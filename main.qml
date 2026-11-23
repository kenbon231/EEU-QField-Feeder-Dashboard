import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.qfield

Item {
    id: plugin

    Component.onCompleted: {
        iface.addItemToPluginsToolbar(dashboardButton)
        iface.mainWindow().displayToast("EEU Feeder Dashboard loaded")
    }

    Component {
        id: dashboardButtonComponent

        Button {
            text: "EEU Dashboard"
            onClicked: dashboardDialog.open()
        }
    }

    property var dashboardButton: dashboardButtonComponent.createObject(
        iface.mainWindow().contentItem
    )

    Dialog {
        id: dashboardDialog
        parent: iface.mainWindow().contentItem
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.95, 900)
        height: parent.height * 0.90
        modal: true
        title: "EEU COP32 – Feeder Construction Dashboard"

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            Label {
                text: "POLES ERECTED  |  MV OVERHEAD (km)  |  INSTALLED TRANSFORMERS"
                font.bold: true
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Label {
                id: statusLabel
                text: "Dashboard loaded. Connect to the project layers to display feeder statistics."
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Button {
                text: "Check project layers"
                onClicked: {
                    let names = ["Pole", "MV_Overhead", "Transformer"]
                    let report = []

                    for (let i = 0; i < names.length; i++) {
                        let layers = qgisProject.mapLayersByName(names[i])
                        if (layers.length > 0) {
                            report.push(names[i] + ": layer found")
                        } else {
                            report.push(names[i] + ": NOT FOUND")
                        }
                    }

                    statusLabel.text = report.join("\n")
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Button {
                text: "Close"
                onClicked: dashboardDialog.close()
            }
        }
    }
}
