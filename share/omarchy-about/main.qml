import QtQuick
import QtQuick.Window
import QtQuick.Layouts

// "About this PC" card for Omarchy. All data + colours come from a JSON file
// produced by the `omarchy-about` launcher and passed as the last argument.
// The interface language (en/es) is chosen from the JSON "lang" field, which
// the launcher derives from the user's locale.
Window {
    id: win

    // ---- data + theme (filled in Component.onCompleted) ----------------
    property var d: ({})
    property var th: ({})
    property string shotPath: ""

    // ---- localisation --------------------------------------------------
    readonly property string lang: (d.lang === "es") ? "es" : "en"
    readonly property var dict: ({
        "en": {
            title: "About This PC", deviceName: "Device name",
            deviceSpecs: "DEVICE SPECIFICATIONS", system: "SYSTEM",
            processor: "Processor", graphics: "Graphics", memory: "Memory (RAM)",
            inUse: "in use", storage: "Storage", freeOf: "free of", display: "Display",
            model: "Model", kernel: "Kernel", arch: "Architecture", uptime: "Uptime",
            theme: "Omarchy theme", copy: "Copy info", copied: "Copied!", close: "Close",
            fallback: "System"
        },
        "es": {
            title: "Acerca de este equipo", deviceName: "Nombre del dispositivo",
            deviceSpecs: "ESPECIFICACIONES DEL DISPOSITIVO", system: "SISTEMA",
            processor: "Procesador", graphics: "Gráficos", memory: "Memoria (RAM)",
            inUse: "en uso", storage: "Almacenamiento", freeOf: "libres de", display: "Pantalla",
            model: "Modelo", kernel: "Kernel", arch: "Arquitectura", uptime: "Tiempo activo",
            theme: "Tema Omarchy", copy: "Copiar info", copied: "¡Copiado!", close: "Cerrar",
            fallback: "Sistema"
        }
    })
    function t(k) { return (dict[lang] && dict[lang][k] !== undefined) ? dict[lang][k] : k }
    function fmtUptime(sec) {
        sec = parseInt(sec) || 0
        var dd = Math.floor(sec / 86400), hh = Math.floor((sec % 86400) / 3600), mm = Math.floor((sec % 3600) / 60)
        var p = []
        if (dd > 0) p.push(dd + " d")
        if (hh > 0) p.push(hh + " h")
        if (mm > 0 || p.length === 0) p.push(mm + " min")
        return p.join(" ")
    }
    function memoryValue() { return d.memory ? d.memory.total + "   ·   " + d.memory.used + " " + t("inUse") : "" }
    function diskValue()   { return d.disk   ? d.disk.free + " " + t("freeOf") + " " + d.disk.total : "" }
    function cpuValue()    { return d.cpu ? d.cpu.model + "   " + d.cpu.cores + "C / " + d.cpu.threads + "T"
                                            + (d.cpu.freq ? " · " + d.cpu.freq : "") : "" }

    // ---- themed palette, with safe fallbacks before data loads ---------
    readonly property color cBg:     th.background  ? th.background  : "#16181d"
    readonly property color cFg:     th.foreground  ? th.foreground  : "#e6e6e6"
    readonly property color cAccent: th.accent      ? th.accent      : "#7aa2f7"
    function mix(a, b, t) { return Qt.rgba(a.r*(1-t)+b.r*t, a.g*(1-t)+b.g*t, a.b*(1-t)+b.b*t, 1) }
    function textOn(c) { return (0.299*c.r + 0.587*c.g + 0.114*c.b) > 0.6 ? "#101010" : "#ffffff" }
    readonly property color cSurface: mix(cBg, cFg, 0.05)
    readonly property color cBorder:  mix(cBg, cFg, 0.14)
    readonly property color cDim:     mix(cBg, cFg, 0.50)

    readonly property int margin: 26
    // Drive height/min/max from one independent expression so the window
    // auto-fits its content without a minimumHeight<->height binding loop.
    readonly property int winHeight: Math.round(col.implicitHeight + 2 * margin)

    width: 600
    minimumWidth: 600;  maximumWidth: 600
    height: winHeight
    minimumHeight: winHeight; maximumHeight: winHeight
    visible: true
    color: cBg
    title: t("title") + " · Omarchy"

    Component.onCompleted: {
        var args = Qt.application.arguments
        var dataPath = ""
        for (var i = 0; i < args.length; i++) {
            if (args[i].indexOf("--shot=") === 0) shotPath = args[i].substring(7)
            else if (args[i].slice(-5) === ".json") dataPath = args[i]
        }
        if (dataPath) {
            try {
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file://" + dataPath, false)
                xhr.send()
                var obj = JSON.parse(xhr.responseText)
                d = obj
                th = obj.theme || ({})
            } catch (e) { console.error("omarchy-about: failed to load data:", e) }
        }
        if (shotPath.length > 0) shotTimer.start()
    }

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }

    // hidden helper used to put the summary on the clipboard
    TextEdit { id: clip; visible: false }
    function summaryText() {
        var L = []
        L.push((d.os ? d.os.name + "  (" + d.os.brand + " · " + d.os.wm + ")" : ""))
        L.push(t("deviceName") + ": " + (d.host ? d.host.hostname : ""))
        L.push(t("model") + ": " + (d.host ? d.host.model : ""))
        L.push(t("processor") + ": " + cpuValue())
        if (d.gpus) for (var i = 0; i < d.gpus.length; i++)
            L.push(t("graphics") + ": " + d.gpus[i].name + (d.gpus[i].vram ? " · " + d.gpus[i].vram : ""))
        L.push(t("memory") + ": " + memoryValue())
        L.push(t("storage") + ": " + diskValue())
        if (d.display) L.push(t("display") + ": " + d.display)
        L.push(t("kernel") + ": " + (d.os ? d.os.kernel : ""))
        L.push(t("arch") + ": " + (d.os ? d.os.arch : ""))
        L.push(t("uptime") + ": " + (d.os ? fmtUptime(d.os.uptime_sec) : ""))
        L.push(t("theme") + ": " + (th.name ? th.name : ""))
        return L.join("\n")
    }
    function copyInfo() { clip.text = summaryText(); clip.selectAll(); clip.copy(); clip.deselect() }

    // ====================================================================
    Item {
        id: content
        anchors.fill: parent

        Rectangle { anchors.fill: parent; color: cBg }

        ColumnLayout {
            id: col
            x: margin; y: margin
            width: parent.width - 2 * margin
            spacing: 16

            // ---- header ------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    implicitWidth: 58; implicitHeight: 58; radius: 14
                    color: cAccent
                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.strokeStyle = "#ffffff"
                            ctx.lineWidth = 2.4
                            ctx.lineJoin = "round"
                            ctx.beginPath(); ctx.strokeRect(15, 16, 28, 19)          // screen
                            ctx.beginPath(); ctx.moveTo(29, 35); ctx.lineTo(29, 41); ctx.stroke() // neck
                            ctx.beginPath(); ctx.moveTo(22, 42); ctx.lineTo(36, 42); ctx.stroke() // base
                        }
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: d.os ? d.os.name : t("fallback")
                        color: cFg; font.pixelSize: 24; font.bold: true
                    }
                    Text {
                        text: d.os ? (d.os.brand + "  ·  " + d.os.wm) : ""
                        color: cAccent; font.pixelSize: 13; font.bold: true
                    }
                }
                Item { Layout.fillWidth: true }
            }

            // device name block
            ColumnLayout {
                Layout.topMargin: 4
                spacing: 1
                Text { text: t("deviceName"); color: cDim; font.pixelSize: 11 }
                Text {
                    text: d.host ? d.host.hostname : ""
                    color: cFg; font.pixelSize: 17; font.bold: true
                }
            }

            // ---- specs panel ------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                color: cSurface
                radius: 12
                border.color: cBorder
                border.width: 1
                implicitHeight: specCol.implicitHeight + 28

                ColumnLayout {
                    id: specCol
                    x: 18; y: 14
                    width: parent.width - 36
                    spacing: 9

                    Text {
                        text: t("deviceSpecs")
                        color: cAccent; font.pixelSize: 11; font.bold: true
                        font.letterSpacing: 1.2
                        Layout.bottomMargin: 2
                    }
                    SpecRow { label: t("processor"); labelColor: cDim; valueColor: cFg; value: cpuValue() }
                    Repeater {
                        model: d.gpus ? d.gpus : []
                        SpecRow {
                            label: index === 0 ? t("graphics") : t("graphics") + " (" + (index + 1) + ")"
                            labelColor: cDim; valueColor: cFg
                            value: modelData.name + (modelData.vram ? "   ·   " + modelData.vram : "")
                        }
                    }
                    SpecRow { label: t("memory");  labelColor: cDim; valueColor: cFg; value: memoryValue() }
                    SpecRow { label: t("storage"); labelColor: cDim; valueColor: cFg; value: diskValue() }
                    SpecRow { label: t("display"); labelColor: cDim; valueColor: cFg; value: d.display ? d.display : "" }
                    SpecRow { label: t("model");   labelColor: cDim; valueColor: cFg; value: d.host ? d.host.model : "" }
                }
            }

            // ---- system panel -----------------------------------------
            Rectangle {
                Layout.fillWidth: true
                color: cSurface
                radius: 12
                border.color: cBorder
                border.width: 1
                implicitHeight: sysCol.implicitHeight + 28

                ColumnLayout {
                    id: sysCol
                    x: 18; y: 14
                    width: parent.width - 36
                    spacing: 9

                    Text {
                        text: t("system")
                        color: cAccent; font.pixelSize: 11; font.bold: true
                        font.letterSpacing: 1.2
                        Layout.bottomMargin: 2
                    }
                    SpecRow { label: t("kernel"); labelColor: cDim; valueColor: cFg; value: d.os ? d.os.kernel : "" }
                    SpecRow { label: t("arch");   labelColor: cDim; valueColor: cFg; value: d.os ? d.os.arch : "" }
                    SpecRow { label: t("uptime"); labelColor: cDim; valueColor: cFg; value: d.os ? fmtUptime(d.os.uptime_sec) : "" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 18
                        Text { text: t("theme"); color: cDim; font.pixelSize: 13; Layout.preferredWidth: 156 }
                        Rectangle { implicitWidth: 13; implicitHeight: 13; radius: 3; color: cAccent; border.width: 1; border.color: cBorder; Layout.alignment: Qt.AlignVCenter }
                        Text { text: th.name ? th.name : ""; color: cFg; font.pixelSize: 13; Layout.fillWidth: true }
                    }
                }
            }

            // ---- buttons ----------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Item { Layout.fillWidth: true }

                Rectangle {
                    id: copyBtn
                    implicitWidth: copyTxt.implicitWidth + 30
                    implicitHeight: 34
                    radius: 8
                    property bool ok: false
                    color: copyMa.containsMouse ? mix(cAccent, cFg, 0.12) : cAccent
                    Text {
                        id: copyTxt
                        anchors.centerIn: parent
                        text: copyBtn.ok ? t("copied") : t("copy")
                        color: textOn(cAccent)
                        font.pixelSize: 13; font.bold: true
                    }
                    MouseArea {
                        id: copyMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { copyInfo(); copyBtn.ok = true; okTimer.restart() }
                    }
                    Timer { id: okTimer; interval: 1400; onTriggered: copyBtn.ok = false }
                }

                Rectangle {
                    implicitWidth: closeTxt.implicitWidth + 30
                    implicitHeight: 34
                    radius: 8
                    color: closeMa.containsMouse ? cSurface : "transparent"
                    border.color: cBorder; border.width: 1
                    Text { id: closeTxt; anchors.centerIn: parent; text: t("close"); color: cFg; font.pixelSize: 13 }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }
        }
    }

    // ---- screenshot mode (docs / verification) -------------------------
    Timer {
        id: shotTimer
        interval: 380
        onTriggered: content.grabToImage(function (res) {
            if (res) res.saveToFile(win.shotPath)
            Qt.quit()
        }, Qt.size(content.width * 2, content.height * 2))
    }
}
