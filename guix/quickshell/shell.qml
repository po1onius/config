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
        // 弹窗里每个设备都要能读/写音量，所以必须把它们全部纳入跟踪
        // （PwNode 上的 audio.volume / audio.muted 未跟踪时无效）。
        objects: {
            var list = []
            if (root.sink)
                list.push(root.sink)
            if (root.source)
                list.push(root.source)
            var vals = Pipewire.nodes.values
            for (var i = 0; i < vals.length; i++)
                if (root.isAudioDevice(vals[i]))
                    list.push(vals[i])
            return list
        }
    }

    // 弹窗开关。PopupWindow 用 grabFocus 让「点外部自动关闭」，
    // 关闭时它会自己把 visible 置 false，所以要靠 onClosed 把状态同步回来，
    // 否则下次点击会被当成「再关一次」而打不开。
    property bool audioPopupOpen: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // 设备分类判据：只用 type / isStream —— 它们是 constant 属性，
    // 建节点时就有值，不依赖「先被跟踪」（properties[…] 反而可能暂时缺失，
    // 会造成漏设备）。实测枚举值：Audio=1 Stream=4 Source=8 Sink=16，
    // AudioSink=17、AudioSource=9 是复合值，所以按 Sink/Source 位判断，
    // 而不是拿 type 和 AudioSink 整体比较。
    function audioClass(n) {
        if (n === null || n === undefined || n.isStream)
            return ""
        var t = n.type
        if ((t & PwNodeType.Audio) === 0)      // 只管音频节点，
            return ""                          // 排掉 video sink 和 Midi-Bridge（type=0）
        var sink = (t & PwNodeType.Sink) !== 0
        var source = (t & PwNodeType.Source) !== 0
        if (sink && source)
            return "Audio/Duplex"
        if (sink)
            return "Audio/Sink"
        if (source)
            return "Audio/Source"
        return ""
    }

    function isAudioDevice(n) {
        return root.audioClass(n) !== ""
    }

    // 弹窗列表：先输出后输入，每项带 kind 供分组标题使用。
    // 只依赖 media.class / isSink / isStream（都不需要先被跟踪），
    // 绝不碰 audio —— 否则会和 PwObjectTracker 形成循环依赖。
    readonly property var audioDevices: {
        var vals = Pipewire.nodes.values
        var outs = []
        var ins = []
        for (var i = 0; i < vals.length; i++) {
            var n = vals[i]
            var mc = root.audioClass(n)
            if (mc === "Audio/Sink" || mc === "Audio/Duplex")
                outs.push({ node: n, kind: "输出" })
            if (mc === "Audio/Source" || mc === "Audio/Duplex")
                ins.push({ node: n, kind: "输入" })
        }
        return outs.concat(ins)
    }
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
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton)
                                root.toggleMute()
                            else
                                root.audioPopupOpen = !root.audioPopupOpen
                        }
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

    // ── 音量 / 设备弹窗 ────────────────────────────────────────────────
    // 挂在音量药丸下边缘、右对齐；grabFocus 负责「点外部自动关闭」。
    // anchor.item 的锚点矩形只在首次显示时算一次，药丸位置是固定的，够用。
    PopupWindow {
        id: audioPopup

        visible: root.audioPopupOpen
        grabFocus: true
        color: "transparent"
        implicitWidth: 320
        implicitHeight: popupColumn.implicitHeight + 20

        anchor.item: volPill
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.margins.top: 8
        anchor.adjustment: PopupAdjustment.Slide

        onClosed: root.audioPopupOpen = false

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Qt.rgba(18 / 255, 20 / 255, 26 / 255, 0.97)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            ColumnLayout {
                id: popupColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    visible: root.audioDevices.length === 0
                    text: "没有找到音频设备"
                    color: root.fgDim
                    font.family: root.uiFont
                    font.pixelSize: 13
                }

                Repeater {
                    model: root.audioDevices

                    delegate: ColumnLayout {
                        id: devRow
                        required property var modelData
                        required property int index

                        readonly property var node: modelData.node
                        readonly property bool isOutput: modelData.kind === "输出"
                        readonly property bool isDefault: isOutput
                                                          ? Pipewire.defaultAudioSink === node
                                                          : Pipewire.defaultAudioSource === node
                        readonly property var audio: node ? node.audio : null
                        readonly property real vol: audio ? audio.volume : 0
                        readonly property bool muted: audio ? audio.muted : false
                        readonly property bool firstOfGroup: index === 0
                                                             || root.audioDevices[index - 1].kind !== modelData.kind

                        Layout.fillWidth: true
                        spacing: 5

                        // 分组标题（输出设备 / 输入设备）
                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: devRow.index === 0 ? 0 : 4
                            visible: devRow.firstOfGroup
                            text: devRow.modelData.kind + "设备"
                            color: root.fgDim
                            font.family: root.uiFont
                            font.pixelSize: 12
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // 默认设备指示点
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                width: 7
                                height: 7
                                radius: 4
                                color: devRow.isDefault ? root.accent : "transparent"
                                border.width: 1
                                border.color: devRow.isDefault ? root.accent
                                                               : Qt.rgba(1, 1, 1, 0.30)
                            }

                            // 设备名：点击设为默认
                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                text: devRow.node
                                      ? (devRow.node.description ? devRow.node.description
                                                                 : devRow.node.name)
                                      : ""
                                color: nameMouse.containsMouse ? root.fg : "#c6cddb"
                                font.family: root.uiFont
                                font.pixelSize: 13
                                font.bold: devRow.isDefault

                                MouseArea {
                                    id: nameMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (devRow.isOutput)
                                            Pipewire.preferredDefaultAudioSink = devRow.node
                                        else
                                            Pipewire.preferredDefaultAudioSource = devRow.node
                                    }
                                }
                            }

                            // 百分比：点击切换静音
                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: devRow.muted ? "静音" : Math.round(devRow.vol * 100) + "%"
                                color: devRow.muted
                                       ? root.danger
                                       : (pctMouse.containsMouse ? root.fg : root.fgDim)
                                font.family: root.uiFont
                                font.pixelSize: 12

                                MouseArea {
                                    id: pctMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (devRow.audio) devRow.audio.muted = !devRow.audio.muted
                                }
                            }
                        }

                        // 可拖动进度条
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 16

                            Rectangle {
                                id: track
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Qt.rgba(1, 1, 1, 0.14)

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, devRow.vol))
                                    height: parent.height
                                    radius: 3
                                    color: (sliderMouse.pressed || sliderMouse.containsMouse)
                                           ? root.accentHover : root.accent

                                    Behavior on color {
                                        ColorAnimation { duration: 110 }
                                    }
                                }
                            }

                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: "#eef2f8"
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(track.width - width,
                                        track.width * Math.max(0, Math.min(1, devRow.vol)) - width / 2))
                            }

                            MouseArea {
                                id: sliderMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                function apply(px) {
                                    if (!devRow.audio)
                                        return
                                    devRow.audio.volume = Math.max(0, Math.min(1, px / width))
                                }

                                onPressed: mouse => apply(mouse.x)
                                onPositionChanged: mouse => {
                                    if (pressed)
                                        apply(mouse.x)
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    visible: root.audioDevices.length > 0
                    text: "点名字设为默认 · 点百分比静音 · 拖动滑块调音量"
                    wrapMode: Text.WordWrap
                    color: Qt.rgba(1, 1, 1, 0.32)
                    font.family: root.uiFont
                    font.pixelSize: 11
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
