// Quickshell bar —— 取代 waybar。
//
// 数据来源：
//   * niri  —— `niri msg`（环境变量 NIRI_SOCKET 由
//              ch0r0ng/services/quickshell.scm 在 Shepherd 里解析好传给 qs）
//   * 网络  —— `iw dev <iface> link`，用 `iw event` 当刷新触发器（无需 root）
//   * 音频  —— Quickshell.Services.Pipewire（直接操作 PipeWire，不用 pamixer/wpctl）
//
// 社区参考（都是零第三方插件的纯配置方案）：
//   * rdnashell  services/Niri.qml  —— Process + `niri msg event-stream` +
//                `niri msg --json workspaces/windows` + JSON.parse
//   * rdnashell  widgets/Audio.qml  —— Pipewire.defaultAudioSink.audio.volume/.muted
//   * niriha     ActionBar.qml      —— PanelWindow + Quickshell.Services.SystemTray
//   （tripleducky 那个 bar 依赖第三方 `qml-niri` 插件，所以没采用。）
//
// 用法：qs -p /path/to/this/dir   或  qs -c <配置名>（放进 ~/.config/quickshell/）

//@ pragma UseQApplication

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    // ── 配色 / 字体（和之前 waybar 的玻璃药丸对齐）────────────────────
    readonly property color barBg: Qt.rgba(16 / 255, 18 / 255, 24 / 255, 0.74)
    readonly property color pillIdle: Qt.rgba(1, 1, 1, 0.05)
    readonly property color pillHover: Qt.rgba(1, 1, 1, 0.14)
    readonly property color accent: "#7fc8ff"
    readonly property color accentHover: "#a8dbff"
    readonly property color fg: "#e6e9ef"
    readonly property color fgDim: "#8b93a7"
    readonly property color danger: "#ff6b6b"
    readonly property string uiFont: "LXGW WenKai Mono"

    // ── niri 状态 ──────────────────────────────────────────────────────
    // 字段名取自 niri-ipc：workspace 有 id/idx/name/is_active/is_focused/
    // is_urgent；window 有 id/title/app_id/is_focused/workspace_id。
    property var workspaces: []
    property var windows: []
    property var focusedWindow: null

    function refreshWorkspaces() { getWorkspaces.running = true }
    function refreshWindows() { getWindows.running = true }

    // 事件流：niri 每次 workspace/window 变化都会吐一行事件名，
    // 收到就重新拉一次 JSON（比轮询省事，也不用自己实现 socket 协议）。
    Process {
        id: eventStream
        running: true
        command: ["niri", "msg", "event-stream"]
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("Workspace"))
                    root.refreshWorkspaces()
                if (data.startsWith("Window"))
                    root.refreshWindows()
            }
        }
    }

    Process {
        id: getWorkspaces
        running: true
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.workspaces = JSON.parse(text)
                } catch (e) {
                    console.warn("quickshell-bar: bad workspaces JSON:", e)
                }
            }
        }
    }

    Process {
        id: getWindows
        running: true
        command: ["niri", "msg", "--json", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windows = JSON.parse(text)
                    var f = null
                    for (var i = 0; i < root.windows.length; i++)
                        if (root.windows[i].is_focused)
                            f = root.windows[i]
                    root.focusedWindow = f
                } catch (e) {
                    console.warn("quickshell-bar: bad windows JSON:", e)
                }
            }
        }
    }

    function focusWorkspace(idx) {
        Quickshell.execDetached({
            command: ["niri", "msg", "action", "focus-workspace", String(idx)]
        })
    }

    // ── 网络（iw）──────────────────────────────────────────────────────
    property string wifiIface: ""
    property string wifiSsid: ""
    property int wifiDbm: 0          // 负值；0 表示没连上
    property bool wifiConnected: false

    // dBm → 百分比，和 waybar 的做法一致（-50dBm 满格，-100dBm 空）
    readonly property int wifiPercent: {
        if (!wifiConnected)
            return 0
        return Math.max(0, Math.min(100, 2 * (wifiDbm + 100)))
    }

    // 启动时找一次无线网卡名
    Process {
        id: findWifi
        running: true
        command: ["sh", "-c", "iw dev 2>/dev/null | awk '/Interface/{print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiIface = text.trim()
                if (root.wifiIface.length > 0)
                    getWifi.running = true
            }
        }
    }

    function parseWifi(out) {
        var connected = false
        var ssid = ""
        var dbm = 0
        var lines = out.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim()
            if (l.indexOf("Connected to") === 0)
                connected = true
            else if (l.indexOf("SSID:") === 0)
                ssid = l.substring(5).trim()
            else if (l.indexOf("signal:") === 0)
                dbm = parseInt(l.substring(7).trim(), 10)
        }
        root.wifiConnected = connected
        root.wifiSsid = ssid
        root.wifiDbm = isNaN(dbm) ? 0 : dbm
    }

    Process {
        id: getWifi
        command: ["iw", "dev", root.wifiIface, "link"]
        stdout: StdioCollector {
            onStreamFinished: root.parseWifi(text)
        }
    }

    // `iw event` 不需要 root：只在有变化时刷新（外加下面的兜底轮询）
    Process {
        id: wifiEvent
        running: true
        command: ["iw", "event"]
        stdout: SplitParser {
            onRead: data => wifiDebounce.restart()
        }
    }

    Timer {
        id: wifiDebounce
        interval: 400
        onTriggered: if (root.wifiIface.length > 0) getWifi.running = true
    }

    Timer {
        interval: 15000          // 兜底，防止漏事件
        running: true
        repeat: true
        onTriggered: if (root.wifiIface.length > 0) getWifi.running = true
    }

    // ── 音频（PipeWire）────────────────────────────────────────────────
    // 注意：PwNode 上的 audio.volume / audio.muted 等属性，必须先由
    // PwObjectTracker 绑定节点才有值（quickshell 上游文档明确说明），
    // 否则读出来永远是 0 / false。
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink !== null && sink !== undefined
                                      && sink.audio !== null && sink.audio !== undefined
    readonly property bool muted: sinkReady ? sink.audio.muted : false
    readonly property int volumePercent: sinkReady ? Math.round(sink.audio.volume * 100) : 0

    function toggleMute() {
        if (sinkReady)
            sink.audio.muted = !sink.audio.muted
    }

    function bumpVolume(delta) {
        if (!sinkReady)
            return
        sink.audio.volume = Math.min(Math.max(sink.audio.volume + delta, 0), 1)
    }

    // ── 面板 ──────────────────────────────────────────────────────────
    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }
        margins {
            top: 6
            left: 10
            right: 10
        }

        implicitHeight: 34
        exclusiveZone: 40          // 34 + 上边距 6，给窗口留出空间
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:bar"

        // 悬浮玻璃药丸
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: root.barBg
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                // ── 左：工作区药丸（hover 变亮，点击切换）──
                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Repeater {
                        model: root.workspaces

                        delegate: Rectangle {
                            id: wsPill
                            required property var modelData

                            readonly property bool focused: modelData.is_active
                            readonly property bool hovered: wsMouse.containsMouse

                            width: Math.max(22, wsLabel.implicitWidth + 14)
                            height: 24
                            radius: 9
                            color: focused
                                   ? (hovered ? root.accentHover : root.accent)
                                   : (modelData.is_urgent
                                      ? root.danger
                                      : (hovered ? root.pillHover : root.pillIdle))

                            Behavior on color {
                                ColorAnimation { duration: 110 }
                            }

                            Text {
                                id: wsLabel
                                anchors.centerIn: parent
                                text: modelData.idx
                                color: wsPill.focused ? "#10131a"
                                                      : (wsPill.hovered ? root.fg : root.fgDim)
                                font.family: root.uiFont
                                font.pixelSize: 13
                                font.bold: wsPill.focused
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.focusWorkspace(modelData.idx)
                            }
                        }
                    }
                }

                // ── 中：当前窗口标题（自动省略）──
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: root.fgDim
                    font.family: root.uiFont
                    font.pixelSize: 13
                    text: {
                        if (!root.focusedWindow)
                            return ""
                        if (root.focusedWindow.title)
                            return root.focusedWindow.title
                        return root.focusedWindow.app_id ? root.focusedWindow.app_id : ""
                    }
                }

                // ── 右：系统托盘（hover 提亮）──
                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    Repeater {
                        model: SystemTray.items

                        delegate: Image {
                            id: trayIcon
                            required property var modelData

                            width: 18
                            height: 18
                            source: modelData.icon
                            smooth: true
                            opacity: trayMouse.containsMouse ? 1.0 : 0.82

                            Behavior on opacity {
                                NumberAnimation { duration: 110 }
                            }

                            MouseArea {
                                id: trayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: modelData.activate()
                            }
                        }
                    }
                }

                // ── 右：网络（iw）── 点击立刻刷新
                Rectangle {
                    id: netPill
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: netLabel.implicitWidth + 18
                    Layout.preferredHeight: 24
                    radius: 9
                    color: netMouse.containsMouse ? root.pillHover : root.pillIdle

                    Behavior on color {
                        ColorAnimation { duration: 110 }
                    }

                    Text {
                        id: netLabel
                        anchors.centerIn: parent
                        font.family: root.uiFont
                        font.pixelSize: 13
                        color: root.wifiConnected
                               ? (netMouse.containsMouse ? root.fg : root.fgDim)
                               : root.fgDim
                        text: {
                            if (root.wifiIface.length === 0)
                                return "no wifi"
                            if (!root.wifiConnected)
                                return "offline"
                            return root.wifiSsid + "  " + root.wifiPercent + "%"
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.wifiIface.length > 0) getWifi.running = true
                    }
                }

                // ── 右：音量（点击静音，滚轮调音量）──
                Rectangle {
                    id: volPill
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: volLabel.implicitWidth + 18
                    Layout.preferredHeight: 24
                    radius: 9
                    color: volMouse.containsMouse ? root.pillHover : root.pillIdle

                    Behavior on color {
                        ColorAnimation { duration: 110 }
                    }

                    Text {
                        id: volLabel
                        anchors.centerIn: parent
                        font.family: root.uiFont
                        font.pixelSize: 13
                        color: root.muted ? root.danger : root.fg
                        text: {
                            if (!root.sinkReady)
                                return "no audio"
                            if (root.muted)
                                return "MUTE"
                            return root.volumePercent + "%"
                        }
                    }

                    MouseArea {
                        id: volMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleMute()
                        onWheel: wheel => root.bumpVolume((wheel.angleDelta.y / 120) * 0.05)
                    }
                }

                // ── 右：时钟（hover 变亮）──
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: clockText.implicitWidth + 20
                    Layout.preferredHeight: 24
                    radius: 9
                    color: clockMouse.containsMouse ? root.pillHover : root.pillIdle

                    Behavior on color {
                        ColorAnimation { duration: 110 }
                    }

                    Text {
                        id: clockText
                        anchors.centerIn: parent
                        color: root.fg
                        font.family: root.uiFont
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        id: clockMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            var wd = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"][d.getDay()]
            clockText.text = Qt.formatDateTime(d, "HH:mm") + "  " + wd
        }
    }
}
