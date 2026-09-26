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

    // ── 网络（iwd / iwctl）─────────────────────────────────────────────
    // 系统的 Wi-Fi 由 iwd 管理（system.scm 里的 iwd-service-type）。iwd 通过
    // D-Bus + polkit 授权，所以 iwctl 普通用户就能扫描/连接；而 `iw scan`
    // 需要 root，所以除了「找网卡名」之外不再用 iw。
    property string wifiIface: ""
    property string wifiState: ""         // connected / disconnected / connecting
    property string wifiSsid: ""
    property int wifiRssi: 0              // 负值 dBm
    property var wifiNetworks: []
    property var wifiKnown: []
    property bool wifiPopupOpen: false
    property var pendingNetwork: null     // 非 null 时弹窗切到「输密码」视图
    property string wifiPassword: ""
    property string wifiMessage: ""

    readonly property bool wifiConnected: wifiState === "connected"

    // 四格信号的格数
    readonly property int wifiLevel: {
        if (!wifiConnected)
            return 0
        if (wifiRssi >= -55)
            return 4
        if (wifiRssi >= -65)
            return 3
        if (wifiRssi >= -75)
            return 2
        return 1
    }

    // 启动时找一次网卡名（iwctl 的 station 参数要用）
    Process {
        id: findWifi
        running: true
        command: ["sh", "-c", "iw dev 2>/dev/null | awk '/Interface/{print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiIface = text.trim()
                if (root.wifiIface.length > 0) {
                    getStation.running = true
                    wifiPoll.start()
                }
            }
        }
    }

    function stripAnsi(s) {
        return s.replace(/\x1b\[[0-9;]*m/g, "")
    }

    // iwctl 的表格是按【显示宽度】对齐的：CJK 名字会让「字符下标」和
    // 「视觉列」错位（比如 保安亭-5G 只占 6 个字符却是 10 列宽），所以不能
    // 按表头下标切片，只能用「2 个以上空格」当分隔符。
    function iwctlRows(out) {
        var lines = root.stripAnsi(out).split("\n")
        var rows = []
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim()
            if (l === "" || l.indexOf("---") === 0)
                continue
            var parts = l.split(/\s{2,}/)
            if (parts.length >= 2)
                rows.push(parts)
        }
        return rows
    }

    // `iwctl station <dev> show` → State / Connected network / RSSI / Security
    function parseStation(out) {
        var rows = root.iwctlRows(out)
        var kv = {}
        for (var i = 0; i < rows.length; i++) {
            if (rows[i][0] === "Settable" || rows[i][0] === "Property")
                continue                      // 表头行
            kv[rows[i][0]] = rows[i][1]
        }
        root.wifiState = kv["State"] ? kv["State"] : ""
        root.wifiSsid = kv["Connected network"] ? kv["Connected network"] : ""
        if (kv["RSSI"]) {
            var n = parseInt(kv["RSSI"], 10)
            root.wifiRssi = isNaN(n) ? 0 : n
        }
        if (root.wifiConnected && root.wifiMessage !== "")
            root.wifiMessage = ""             // 连上之后清掉「正在连接…」
    }

    // `iwctl station <dev> get-networks` → [{name, security, level, connected}]
    function parseNetworks(out) {
        var lines = root.stripAnsi(out).split("\n")
        var list = []
        var started = false
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim()
            if (l === "")
                continue
            if (l.indexOf("Network name") === 0) {
                started = true
                continue
            }
            if (!started || l.indexOf("---") >= 0)
                continue
            var connected = false
            if (l.charAt(0) === ">") {        // 当前连接的那条
                connected = true
                l = l.substring(1).trim()
            }
            var parts = l.split(/\s{2,}/)
            if (parts.length < 2 || parts[0] === "")
                continue
            list.push({
                name: parts[0],
                security: parts[1],
                level: parts.length > 2 ? parts[2].replace(/\s/g, "").length : 0,
                connected: connected
            })
        }
        return list
    }

    // `iwctl known-networks list` → ["2568", ...]，已保存的不用再输密码
    function parseKnown(out) {
        var lines = root.stripAnsi(out).split("\n")
        var names = []
        var started = false
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim()
            if (l === "")
                continue
            if (l.indexOf("Name") === 0 && l.indexOf("Security") > 0) {
                started = true
                continue
            }
            if (!started || l.indexOf("---") >= 0)
                continue
            var parts = l.split(/\s{2,}/)
            if (parts.length >= 2 && parts[0] !== "")
                names.push(parts[0])
        }
        return names
    }

    function isKnown(ssid) {
        return root.wifiKnown.indexOf(ssid) >= 0
    }

    Process {
        id: getStation
        command: ["iwctl", "station", root.wifiIface, "show"]
        stdout: StdioCollector {
            onStreamFinished: root.parseStation(text)
        }
    }

    Process {
        id: listWifi
        command: ["iwctl", "station", root.wifiIface, "get-networks"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiNetworks = root.parseNetworks(text)
        }
    }

    Process {
        id: listKnown
        command: ["iwctl", "known-networks", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiKnown = root.parseKnown(text)
        }
    }

    // 扫描是异步的，扫完再拉一次列表
    Process {
        id: scanWifi
        command: ["iwctl", "station", root.wifiIface, "scan"]
        onExited: wifiRescan.restart()
    }

    Process {
        id: connectWifi
        property string output: ""
        command: ["iwctl", "station", root.wifiIface, "connect", ""]
        // 用 SplitParser 边收边拼，避免 onExited 时 stdio 还没 flush
        stdout: SplitParser {
            onRead: data => connectWifi.output += data + "\n"
        }
        stderr: SplitParser {
            onRead: data => connectWifi.output += data + "\n"
        }
        onExited: {
            var msg = root.stripAnsi(connectWifi.output).trim()
            connectWifi.output = ""
            root.wifiMessage = msg !== "" ? msg : "连接请求已发送"
            getStation.running = true
            listWifi.running = true
        }
    }

    function refreshWifi(doScan) {
        if (root.wifiIface.length === 0)
            return
        getStation.running = true
        listKnown.running = true
        listWifi.running = true
        if (doScan)
            scanWifi.running = true
    }

    function openWifiPopup() {
        root.wifiPopupOpen = true
        root.pendingNetwork = null
        root.wifiPassword = ""
        root.wifiMessage = ""
        root.refreshWifi(true)
    }

    function chooseNetwork(net) {
        if (net.connected) {
            root.wifiMessage = "已经连在这个网络上了"
            return
        }
        if (net.security === "8021x") {
            // 企业认证要用户名+密码（可能还有证书），不是简单 passphrase
            root.wifiMessage = "企业认证(8021x)网络请用 iwctl 手动连接"
            return
        }
        if (net.security === "open" || root.isKnown(net.name)) {
            // 开放网络或已保存的网络：直接连，不用密码
            root.pendingNetwork = null
            root.wifiMessage = "正在连接 " + net.name + " …"
            connectWifi.command = ["iwctl", "station", root.wifiIface, "connect", net.name]
            connectWifi.running = true
        } else {
            root.pendingNetwork = net
            root.wifiPassword = ""
            root.wifiMessage = ""
        }
    }

    function submitWifiPassword() {
        if (!root.pendingNetwork || root.wifiPassword.length === 0)
            return
        var ssid = root.pendingNetwork.name
        // 注意：--passphrase 会出现在进程参数里（同机普通用户看不到，
        // root 能看到）。iwctl 也支持交互式提示，但那需要一个 tty。
        root.wifiMessage = "正在连接 " + ssid + " …"
        connectWifi.command = ["iwctl", "--passphrase", root.wifiPassword,
                               "station", root.wifiIface, "connect", ssid]
        connectWifi.running = true
        root.pendingNetwork = null
        root.wifiPassword = ""
    }

    function cancelWifiPassword() {
        root.pendingNetwork = null
        root.wifiPassword = ""
        root.wifiMessage = ""
    }

    Timer {
        id: wifiPoll
        interval: 5000
        repeat: true
        onTriggered: if (root.wifiIface.length > 0) getStation.running = true
    }

    Timer {
        id: wifiRescan
        interval: 3500
        onTriggered: if (root.wifiIface.length > 0) listWifi.running = true
    }

    // 弹窗开着时定期刷新列表
    Timer {
        interval: 4000
        running: root.wifiPopupOpen
        repeat: true
        onTriggered: root.refreshWifi(false)
    }

    // ── 托盘菜单（自渲染）──────────────────────────────────────────────
    // 不用 SystemTrayItem.display()：它走 QtWidgets 的 QMenu + QtWayland
    // 原生 popup，父窗口是 layer surface 时挂不上（实测报
    // "Cannot attach popup ... as the popup is not an xdg_popup"）。
    // 改用 QsMenuOpener 读应用的 DBusMenu 自己画。
    property var trayMenuStack: []        // [{handle, title}]，末项是当前层
    property real trayMenuX: 0
    property real trayMenuY: 0
    property string trayMenuHint: ""      // 子菜单等已知限制的提示

    readonly property bool trayMenuOpen: trayMenuStack.length > 0
    readonly property var trayMenuCurrent: trayMenuOpen
                                           ? trayMenuStack[trayMenuStack.length - 1].handle
                                           : null
    readonly property var trayMenuEntries: trayMenuOpener.children
                                           ? trayMenuOpener.children.values : []

    QsMenuOpener {
        id: trayMenuOpener
        menu: root.trayMenuCurrent
    }

    function openTrayMenu(item, x, y) {
        root.trayMenuStack = [{
            handle: item.menu,
            title: item.title ? item.title : item.id
        }]
        root.trayMenuX = x
        root.trayMenuY = y
        root.trayMenuHint = ""
    }

    function closeTrayMenu() {
        // 逐层通知「子菜单已关闭」
        for (var i = root.trayMenuStack.length - 1; i >= 1; i--) {
            var e = root.trayMenuStack[i].handle
            if (e && e.closed)
                e.closed()
        }
        root.trayMenuStack = []
    }

    function activateTrayEntry(entry) {
        if (!entry || !entry.enabled)
            return
        if (entry.hasChildren) {
            // 子菜单暂时做不到：详见文件顶部 trayMenuStack 附近的说明。
            root.trayMenuHint = "这一项是子菜单，暂不支持展开；请在应用里操作"
        } else {
            if (entry.triggered)
                entry.triggered()     // DBusMenuItem 把这个信号接到 D-Bus clicked
            root.closeTrayMenu()
        }
    }

    function trayMenuBack() {
        if (root.trayMenuStack.length <= 1)
            return
        var st = root.trayMenuStack.slice()
        var last = st.pop()
        root.trayMenuStack = st
        if (last.handle && last.handle.closed)
            last.handle.closed()
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
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                                 | Qt.RightButton

                                // 菜单由应用通过 DBusMenu 提供，我们自己画
                                // （见下面的 trayMenuPopup）。坐标要相对【父窗口】，
                                // 所以做一次 mapToItem。
                                function popupMenu() {
                                    var item = trayIcon.modelData
                                    if (!item.hasMenu)
                                        return false
                                    var p = trayIcon.mapToItem(bar.contentItem, 0, 0)
                                    root.openTrayMenu(item, Math.round(p.x),
                                                      Math.round(p.y + trayIcon.height))
                                    return true
                                }

                                onClicked: mouse => {
                                    var item = trayIcon.modelData
                                    if (mouse.button === Qt.RightButton) {
                                        // 再点一次同一个图标 = 收起，否则弹菜单
                                        if (root.trayMenuOpen)
                                            root.closeTrayMenu()
                                        else
                                            popupMenu()
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        item.secondaryActivate()
                                    } else if (item.onlyMenu && popupMenu()) {
                                        // 这类 item 左键激活是空的，只有菜单
                                    } else {
                                        item.activate()
                                    }
                                }

                                onWheel: wheel => trayIcon.modelData.scroll(
                                              wheel.angleDelta.y, wheel.angleDelta.x !== 0)
                            }
                        }
                    }
                }

                // ── 右：Wi-Fi 图标（点击开 Wi-Fi 弹窗）──
                Rectangle {
                    id: netPill
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 24
                    radius: 9
                    color: (netMouse.containsMouse || root.wifiPopupOpen)
                           ? root.pillHover : root.pillIdle

                    Behavior on color {
                        ColorAnimation { duration: 110 }
                    }

                    // 四根柱子画信号格；没连上时全暗并划一道斜杠
                    Item {
                        id: wifiIcon
                        anchors.centerIn: parent
                        width: 15
                        height: 13

                        Repeater {
                            model: 4

                            delegate: Rectangle {
                                required property int index

                                width: 3
                                height: 4 + index * 3
                                x: index * 4
                                y: wifiIcon.height - height
                                radius: 1
                                color: index < root.wifiLevel
                                       ? (netMouse.containsMouse ? root.accentHover : root.accent)
                                       : Qt.rgba(1, 1, 1, 0.22)

                                Behavior on color {
                                    ColorAnimation { duration: 110 }
                                }
                            }
                        }

                        Rectangle {
                            visible: !root.wifiConnected
                            anchors.centerIn: parent
                            width: 18
                            height: 2
                            radius: 1
                            rotation: -45
                            color: root.fgDim
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.wifiPopupOpen) {
                                root.wifiPopupOpen = false
                                root.pendingNetwork = null
                            } else {
                                root.openWifiPopup()
                            }
                        }
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

    // ── Wi-Fi 弹窗 ─────────────────────────────────────────────────────
    // 两个视图共用同一个弹窗：pendingNetwork 为 null 时是网络列表，
    // 否则切到「输入密码」。这样不用嵌套 popup（Wayland 下更省事）。
    PopupWindow {
        id: wifiPopup

        visible: root.wifiPopupOpen
        grabFocus: true
        color: "transparent"
        implicitWidth: 340
        implicitHeight: wifiColumn.implicitHeight + 24

        anchor.item: netPill
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.margins.top: 8
        anchor.adjustment: PopupAdjustment.Slide

        onClosed: {
            root.wifiPopupOpen = false
            root.pendingNetwork = null
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Qt.rgba(18 / 255, 20 / 255, 26 / 255, 0.97)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            ColumnLayout {
                id: wifiColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // 标题 + 重新扫描
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        elide: Text.ElideRight
                        text: root.wifiConnected
                              ? "已连接 " + root.wifiSsid
                              : (root.wifiState === "connecting" ? "连接中…" : "Wi-Fi 未连接")
                        color: root.fg
                        font.family: root.uiFont
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "重新扫描"
                        color: refreshMouse.containsMouse ? root.accentHover : root.fgDim
                        font.family: root.uiFont
                        font.pixelSize: 12

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshWifi(true)
                        }
                    }
                }

                // ── 视图 A：网络列表 ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: root.pendingNetwork === null

                    Text {
                        Layout.fillWidth: true
                        visible: root.wifiNetworks.length === 0
                        text: "正在扫描…"
                        color: root.fgDim
                        font.family: root.uiFont
                        font.pixelSize: 13
                    }

                    Repeater {
                        model: root.wifiNetworks

                        delegate: Rectangle {
                            id: netRow
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 8
                            color: netRowMouse.containsMouse ? root.pillHover : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 110 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                // 信号格（小号）
                                Item {
                                    Layout.alignment: Qt.AlignVCenter
                                    width: 13
                                    height: 11

                                    Repeater {
                                        model: 4

                                        delegate: Rectangle {
                                            required property int index

                                            width: 2.5
                                            height: 3 + index * 2.5
                                            x: index * 3.5
                                            y: 11 - height
                                            radius: 1
                                            color: index < netRow.modelData.level
                                                   ? (netRow.modelData.connected ? root.accent : root.fg)
                                                   : Qt.rgba(1, 1, 1, 0.22)
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    elide: Text.ElideRight
                                    text: netRow.modelData.name
                                    color: netRow.modelData.connected
                                           ? root.accent
                                           : (netRowMouse.containsMouse ? root.fg : "#c6cddb")
                                    font.family: root.uiFont
                                    font.pixelSize: 13
                                    font.bold: netRow.modelData.connected
                                }

                                Text {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: netRow.modelData.security === "open"
                                          ? ""
                                          : (root.isKnown(netRow.modelData.name)
                                             ? "已保存" : netRow.modelData.security)
                                    color: root.fgDim
                                    font.family: root.uiFont
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                id: netRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.chooseNetwork(netRow.modelData)
                            }
                        }
                    }
                }

                // ── 视图 B：输入密码 ──
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.pendingNetwork !== null
                    onVisibleChanged: if (visible) pwInput.forceActiveFocus()

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: root.pendingNetwork ? "连接到 " + root.pendingNetwork.name : ""
                        color: root.fg
                        font.family: root.uiFont
                        font.pixelSize: 13
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.07)
                        border.width: 1
                        border.color: pwInput.activeFocus ? root.accent
                                                          : Qt.rgba(1, 1, 1, 0.12)

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pwInput.text === ""
                            text: "密码"
                            color: Qt.rgba(1, 1, 1, 0.30)
                            font.family: root.uiFont
                            font.pixelSize: 13
                        }

                        TextInput {
                            id: pwInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            selectByMouse: true
                            color: root.fg
                            font.family: root.uiFont
                            font.pixelSize: 13
                            onTextChanged: root.wifiPassword = text
                            onAccepted: root.submitWifiPassword()
                            Keys.onEscapePressed: root.cancelWifiPassword()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 8
                            color: okMouse.containsMouse ? root.accentHover : root.accent

                            Text {
                                anchors.centerIn: parent
                                text: "连接"
                                color: "#10131a"
                                font.family: root.uiFont
                                font.pixelSize: 13
                                font.bold: true
                            }

                            MouseArea {
                                id: okMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.submitWifiPassword()
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 8
                            color: cancelMouse.containsMouse ? root.pillHover : root.pillIdle

                            Text {
                                anchors.centerIn: parent
                                text: "取消"
                                color: root.fgDim
                                font.family: root.uiFont
                                font.pixelSize: 13
                            }

                            MouseArea {
                                id: cancelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.cancelWifiPassword()
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.wifiMessage !== ""
                    text: root.wifiMessage
                    wrapMode: Text.WordWrap
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.family: root.uiFont
                    font.pixelSize: 11
                }

                Text {
                    Layout.fillWidth: true
                    text: "点网络连接 · 已保存/开放网络直接连 · Esc 返回"
                    wrapMode: Text.WordWrap
                    color: Qt.rgba(1, 1, 1, 0.32)
                    font.family: root.uiFont
                    font.pixelSize: 11
                }
            }
        }
    }

    // ── 托盘菜单弹窗 ───────────────────────────────────────────────────
    // 锚在图标正下方，菜单内容来自 QsMenuOpener。
    PopupWindow {
        id: trayMenuPopup

        visible: root.trayMenuOpen
        grabFocus: true
        color: "transparent"
        implicitWidth: 230
        implicitHeight: trayMenuColumn.implicitHeight + 16

        anchor.window: bar
        anchor.rect.x: root.trayMenuX
        anchor.rect.y: root.trayMenuY
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip

        onClosed: root.closeTrayMenu()

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Qt.rgba(18 / 255, 20 / 255, 26 / 255, 0.97)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            // Esc 返回上一层（需要键盘焦点，grabFocus 会把它给本窗口）
            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: {
                    if (root.trayMenuStack.length > 1)
                        root.trayMenuBack()
                    else
                        root.closeTrayMenu()
                }
            }

            ColumnLayout {
                id: trayMenuColumn
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                // 子菜单标题 + 返回
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    visible: root.trayMenuStack.length > 1
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "返回"
                        color: backMouse.containsMouse ? root.accentHover : root.fgDim
                        font.family: root.uiFont
                        font.pixelSize: 12

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.trayMenuBack()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        elide: Text.ElideRight
                        text: root.trayMenuOpen
                              ? root.trayMenuStack[root.trayMenuStack.length - 1].title : ""
                        color: root.fg
                        font.family: root.uiFont
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.trayMenuHint !== ""
                    text: root.trayMenuHint
                    wrapMode: Text.WordWrap
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: root.uiFont
                    font.pixelSize: 11
                }

                Repeater {
                    model: root.trayMenuEntries

                    delegate: Item {
                        id: menuRow
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: menuRow.modelData.isSeparator ? 7 : 26

                        readonly property bool usable: !modelData.isSeparator
                                                       && modelData.enabled

                        // 悬停底色（先声明，画在内容下面）
                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: (rowMouse.containsMouse && menuRow.usable)
                                   ? root.pillHover : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: 90 }
                            }
                        }

                        // 分隔线
                        Rectangle {
                            visible: menuRow.modelData.isSeparator
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.10)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6
                            visible: !menuRow.modelData.isSeparator

                            // 勾选标记：纯自绘，不依赖字体符号
                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                width: 10
                                height: 10
                                visible: menuRow.modelData.buttonType !== QsMenuButtonType.None

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8
                                    height: 8
                                    radius: menuRow.modelData.buttonType === QsMenuButtonType.RadioButton
                                            ? 4 : 2
                                    color: menuRow.modelData.checkState === Qt.Checked
                                           ? root.accent : "transparent"
                                    border.width: 1
                                    border.color: menuRow.modelData.checkState === Qt.Checked
                                                  ? root.accent : Qt.rgba(1, 1, 1, 0.35)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                elide: Text.ElideRight
                                text: menuRow.modelData.text
                                color: !menuRow.modelData.enabled
                                       ? Qt.rgba(1, 1, 1, 0.28)
                                       : (rowMouse.containsMouse ? root.fg : "#c6cddb")
                                font.family: root.uiFont
                                font.pixelSize: 13
                            }

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                visible: menuRow.modelData.hasChildren
                                text: ">"
                                color: root.fgDim
                                font.family: root.uiFont
                                font.pixelSize: 12
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: menuRow.usable
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.activateTrayEntry(menuRow.modelData)
                        }
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
