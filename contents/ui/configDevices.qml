import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes
import org.kde.plasma.private.volume

import "../tools/deviceIcons.js" as DeviceIcons

KCM.ScrollViewKCM {
    id: root

    forceFooterSeparator: true

    property var    cfg_deviceOrder:     []
    property var    cfg_excludedDevices: []
    property string cfg_deviceIcons:     "{}"

    property var    cfg_deviceOrderDefault:     []
    property var    cfg_excludedDevicesDefault: []
    property string cfg_deviceIconsDefault

    readonly property real hintOpacity: 0.7

    property var  connectedSinks: []
    property bool isCommitting:   false

    onCfg_deviceOrderChanged:     if (!isCommitting) Qt.callLater(rebuildRows)
    onCfg_excludedDevicesChanged: if (!isCommitting) Qt.callLater(rebuildRows)
    onCfg_deviceIconsChanged:     if (!isCommitting) Qt.callLater(rebuildRows)

    function parseDeviceIcons(): var {
        try {
            return JSON.parse(cfg_deviceIcons);
        } catch (error) {
            console.warn("audioswitch: ignoring invalid deviceIcons setting:", error.message);
            return {};
        }
    }

    function rebuildRows(): void {
        const customIcons = parseDeviceIcons();

        const rankOf = sink => {
            const position = cfg_deviceOrder.indexOf(sink.name);
            return position === -1 ? cfg_deviceOrder.length : position;
        };

        const sortedSinks = connectedSinks.slice().sort((first, second) => rankOf(first) - rankOf(second));

        deviceRows.clear();

        for (const sink of sortedSinks) {
            deviceRows.append({
                deviceName:        sink.name,
                deviceDescription: sink.description,
                systemIcon:        DeviceIcons.systemIconFor(sink.iconName, AudioIcon.forFormFactor(sink.formFactor)),
                customIcon:        customIcons[sink.name] ?? "",
                isIncluded:        !cfg_excludedDevices.includes(sink.name),
            });
        }
    }

    function commitRows(): void {
        const names       = [];
        const excluded    = [];
        const customIcons = parseDeviceIcons();

        for (let i = 0; i < deviceRows.count; i++) {
            const row = deviceRows.get(i);
            names.push(row.deviceName);
            if (!row.isIncluded) excluded.push(row.deviceName);
            if (row.customIcon !== "") customIcons[row.deviceName] = row.customIcon;
            else delete customIcons[row.deviceName];
        }

        isCommitting = true;

        // shortcut: disconnected devices go to the end of the order, upgrade if their place matters
        cfg_deviceOrder     = names.concat(cfg_deviceOrder.filter(name => !names.includes(name)));
        cfg_excludedDevices = excluded.concat(cfg_excludedDevices.filter(name => !names.includes(name)));
        cfg_deviceIcons     = JSON.stringify(customIcons);

        isCommitting = false;
    }

    ListModel {
        id: deviceRows
    }

    Repeater {
        model: SinkModel {}
        delegate: Item {
            required property var model
            readonly property var sink: model.PulseObject

            Component.onCompleted: {
                root.connectedSinks = [...root.connectedSinks, sink];
                Qt.callLater(root.rebuildRows);
            }

            Component.onDestruction: {
                root.connectedSinks = root.connectedSinks.filter(other => other !== sink);
                Qt.callLater(root.rebuildRows);
            }
        }
    }

    header: QQC2.Label {
        text:     i18n("Drag to set the order, untick a device to skip it and pick an icon to replace the one the system gives it.")
        font:     Kirigami.Theme.smallFont
        opacity:  root.hintOpacity
        wrapMode: Text.Wrap
        padding:  Kirigami.Units.smallSpacing
    }

    view: ListView {
        id:    deviceList
        clip:  true
        model: deviceRows

        Kirigami.PlaceholderMessage {
            visible: deviceRows.count === 0
            anchors.centerIn: parent
            width:       parent.width - Kirigami.Units.gridUnit * 4
            text:        i18n("No output devices found")
            explanation: i18n("Connect speakers or headphones and they will show up here")
        }

        moveDisplaced: Transition {
            YAnimator {
                duration:    Kirigami.Units.longDuration
                easing.type: Easing.InOutQuad
            }
        }

        // the drag handle needs 'listItem' inside the delegate and the context "index", so no required properties
        delegate: Item {
            id: row

            readonly property string deviceDescription: model.deviceDescription
            readonly property string systemIcon:        model.systemIcon
            readonly property string customIcon:        model.customIcon
            readonly property bool   isIncluded:        model.isIncluded

            readonly property bool   hasCustomIcon: customIcon !== ""
            readonly property string shownIcon:     hasCustomIcon ? customIcon : systemIcon

            width:  ListView.view.width
            height: dragItem.implicitHeight

            QQC2.ItemDelegate {
                id:    dragItem
                width: parent.width

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.ListItemDragHandle {
                        listItem: dragItem
                        listView: deviceList
                        onMoveRequested: (oldIndex, newIndex) => {
                            deviceRows.move(oldIndex, newIndex, 1);
                            root.commitRows();
                        }
                    }

                    QQC2.CheckBox {
                        checked: row.isIncluded
                        Accessible.name: i18n("Include %1 in the rotation", row.deviceDescription)
                        onToggled: {
                            deviceRows.setProperty(index, "isIncluded", checked);
                            root.commitRows();
                        }
                    }

                    QQC2.Button {
                        icon.name:   row.shownIcon
                        icon.width:  Kirigami.Units.iconSizes.medium
                        icon.height: Kirigami.Units.iconSizes.medium
                        display:     QQC2.AbstractButton.IconOnly
                        text:        i18n("Choose icon for %1", row.deviceDescription)
                        onClicked:   iconDialog.open()

                        QQC2.ToolTip.text:    text
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay:   Kirigami.Units.toolTipDelay

                        KIconThemes.IconDialog {
                            id: iconDialog
                            onAccepted: {
                                deviceRows.setProperty(index, "customIcon", iconName);
                                root.commitRows();
                            }
                        }
                    }

                    QQC2.Label {
                        text:  row.deviceDescription
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    QQC2.ToolButton {
                        icon.name: "edit-reset"
                        display:   QQC2.AbstractButton.IconOnly
                        text:      i18n("Reset icon of %1", row.deviceDescription)
                        enabled:   row.hasCustomIcon
                        onClicked: {
                            deviceRows.setProperty(index, "customIcon", "");
                            root.commitRows();
                        }

                        QQC2.ToolTip.text:    text
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay:   Kirigami.Units.toolTipDelay
                    }
                }
            }
        }
    }
}
