import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.qfield
import org.qfield.gui

Item {
    id: plugin
    objectName: "eeuFeederDashboard"

    property var mainWindow: iface.mainWindow()
    property var feederRows: []
    property string statusText: "Open the dashboard and press Refresh."
    property int maxPoles: 1
    property int maxKm: 1
    property int maxTransformers: 1

    function layerByName(name) {
        var found = qgisProject.mapLayersByName(name)
        return found && found.length > 0 ? found[0] : null
    }

    function fieldExists(layer, fieldName) {
        return layer && layer.fields().indexOf(fieldName) >= 0
    }

    function addValue(obj, key, amount) {
        if (!obj[key])
            obj[key] = 0
        obj[key] += amount
    }

    function readLayer(layer, kind, totals) {
        if (!layer)
            throw new Error(kind + " layer not found")
        if (!fieldExists(layer, "Feeder_Name"))
            throw new Error(kind + " layer is missing Feeder_Name")

        if (kind === "MV_Overhead" && !fieldExists(layer, "Length_m"))
            throw new Error("MV_Overhead layer is missing Length_m")
        if (kind === "Transformer" && !fieldExists(layer, "Transformer_Status"))
            throw new Error("Transformer layer is missing Transformer_Status")

        var it = LayerUtils.createFeatureIterator(layer)
        while (it.hasNext()) {
            var f = it.next()
            var feeder = String(f.attribute("Feeder_Name") || "").trim()
            if (feeder.length === 0)
                feeder = "(Feeder not assigned)"
            if (!totals[feeder])
                totals[feeder] = { feeder: feeder, poles: 0, km: 0, transformers: 0 }

            if (kind === "Pole") {
                totals[feeder].poles += 1
            } else if (kind === "MV_Overhead") {
                var metres = Number(f.attribute("Length_m"))
                if (isFinite(metres) && metres > 0)
                    totals[feeder].km += metres / 1000.0
            } else if (kind === "Transformer") {
                var state = String(f.attribute("Transformer_Status") || "").trim().toLowerCase()
                if (state === "installed")
                    totals[feeder].transformers += 1
            }
        }
    }

    function refreshDashboard() {
        try {
            var poleLayer = layerByName("Pole")
            var lineLayer = layerByName("MV_Overhead")
            var transformerLayer = layerByName("Transformer")
            var totals = ({})
            readLayer(poleLayer, "Pole", totals)
            readLayer(lineLayer, "MV_Overhead", totals)
            readLayer(transformerLayer, "Transformer", totals)

            var result = []
            var keys = Object.keys(totals).sort()
            var pMax = 1, kMax = 1, tMax = 1
            for (var i = 0; i < keys.length; i++) {
                var row = totals[keys[i]]
                pMax = Math.max(pMax, row.poles)
                kMax = Math.max(kMax, row.km)
                tMax = Math.max(tMax, row.transformers)
                result.push(row)
            }
            feederRows = result
            maxPoles = pMax
            maxKm = kMax
            maxTransformers = tMax
            statusText = result.length + " feeders | Updated " + new Date().toLocaleTimeString()
        } catch (e) {
            statusText = "Dashboard error: " + e
            feederRows = []
        }
    }

    Component.onCompleted: {
        iface.addItemToPluginsToolbar(openDashboardButton)
        iface.mainWindow().displayToast("EEU Feeder Dashboard loaded")
    }

    QfToolButton {
        id: openDashboardButton
        iconSource: "qrc:/images/themes/default/mActionStatistics.svg"
        iconColor: "white"
        bgcolor: "#1769aa"
        round: true
        onClicked: {
            dashboardDialog.open()
            plugin.refreshDashboard()
        }
    }

    Dialog {
        id: dashboardDialog
        parent: plugin.mainWindow.contentItem
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.96, 1000)
        height: parent.height * 0.92
        modal: true
        title: "EEU COP32 – Feeder Construction Dashboard"

        onOpened: plugin.refreshDashboard()

        Timer {
            interval: 15000
            running: dashboardDialog.visible
            repeat: true
            onTriggered: plugin.refreshDashboard()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "ALL FEEDERS – POLES ERECTED | MV OVERHEAD (km) | INSTALLED TRANSFORMERS"
                font.bold: true
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Label {
                text: plugin.statusText
                color: "#555555"
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Label { text: "FEEDER"; font.bold: true; Layout.fillWidth: true }
                Label { text: "POLES"; font.bold: true; width: 65; horizontalAlignment: Text.AlignRight }
                Label { text: "MV km"; font.bold: true; width: 75; horizontalAlignment: Text.AlignRight }
                Label { text: "TRANS."; font.bold: true; width: 75; horizontalAlignment: Text.AlignRight }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: plugin.feederRows

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 112
                            radius: 7
                            color: index % 2 === 0 ? "#f1f5f9" : "#ffffff"
                            border.color: "#d6dde5"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: modelData.feeder
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: modelData.poles.toString()
                                        width: 65
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Label {
                                        text: modelData.km.toFixed(2)
                                        width: 75
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Label {
                                        text: modelData.transformers.toString()
                                        width: 75
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    Label { text: "Poles"; width: 48; font.pixelSize: 11 }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 9
                                        radius: 4
                                        color: "#dce5ee"
                                        Rectangle {
                                            width: parent.width * (modelData.poles / plugin.maxPoles)
                                            height: parent.height
                                            radius: 4
                                            color: "#25864b"
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    Label { text: "MV km"; width: 48; font.pixelSize: 11 }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 9
                                        radius: 4
                                        color: "#dce5ee"
                                        Rectangle {
                                            width: parent.width * (modelData.km / plugin.maxKm)
                                            height: parent.height
                                            radius: 4
                                            color: "#2475b9"
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    Label { text: "Tx"; width: 48; font.pixelSize: 11 }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 9
                                        radius: 4
                                        color: "#dce5ee"
                                        Rectangle {
                                            width: parent.width * (modelData.transformers / plugin.maxTransformers)
                                            height: parent.height
                                            radius: 4
                                            color: "#d18b24"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        visible: plugin.feederRows.length === 0
                        text: "No feeder records found yet. Check that the three project layers contain features."
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Button {
                    text: "Refresh now"
                    onClicked: plugin.refreshDashboard()
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Close"
                    onClicked: dashboardDialog.close()
                }
            }
        }
    }
}
