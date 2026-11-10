import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmaExtras.Representation {
    id: root

    required property var enabledOutputs
    required property var skippedOutputs
    required property var iconFor

    property bool   isPinned: false
    property string emptyTitle
    property string emptyHint

    signal outputPicked(var sink)
    signal pinToggled(bool shouldStayOpen)
    signal settingsRequested()

    readonly property real minWidthGu:  18
    readonly property real minHeightGu: 8
    readonly property real maxHeightGu: 24
    readonly property real iconSize:    Kirigami.Units.iconSizes.medium
    readonly property real rowHeight:   41

    readonly property var entries: {
        const rows = [];
        const addSection = (title, sinks) => {
            if (sinks.length === 0) return;
            rows.push({ isHeader: true, title: title });
            for (const sink of sinks) rows.push({ isHeader: false, sink: sink });
        };
        addSection(i18n("Enabled"), enabledOutputs);
        addSection(i18n("Skipped"), skippedOutputs);
        return rows;
    }

    Layout.minimumWidth:  Kirigami.Units.gridUnit * minWidthGu
    Layout.minimumHeight: Kirigami.Units.gridUnit * minHeightGu

    header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            PlasmaExtras.Heading {
                text:  i18n("Output devices")
                level: 3
                elide: Text.ElideRight
                Layout.fillWidth:  true
                Layout.leftMargin: Kirigami.Units.smallSpacing
            }

            PlasmaComponents3.ToolButton {
                icon.name: "configure"
                display:   PlasmaComponents3.AbstractButton.IconOnly
                text:      i18n("Open settings")
                onClicked: root.settingsRequested()

                PlasmaComponents3.ToolTip.text:    text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay:   Kirigami.Units.toolTipDelay
            }

            PlasmaComponents3.ToolButton {
                checkable: true
                checked:   root.isPinned
                icon.name: "window-pin"
                display:   PlasmaComponents3.AbstractButton.IconOnly
                text:      i18n("Keep open")
                onToggled: root.pinToggled(checked)

                PlasmaComponents3.ToolTip.text:    text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay:   Kirigami.Units.toolTipDelay
            }
        }
    }

    contentItem: PlasmaComponents3.ScrollView {
        implicitHeight: Math.min(Math.max(outputList.contentHeight, Kirigami.Units.gridUnit * root.minHeightGu), Kirigami.Units.gridUnit * root.maxHeightGu)

        ListView {
            id: outputList

            clip:    true
            spacing: Kirigami.Units.smallSpacing
            model:   root.entries

            highlight: PlasmaExtras.Highlight {}
            highlightMoveDuration:   0
            highlightResizeDuration: 0
            currentIndex: -1

            onCountChanged: currentIndex = -1 // highlight must only follow hover

            PlasmaExtras.PlaceholderMessage {
                visible: outputList.count === 0
                anchors.centerIn: parent
                width:       parent.width - Kirigami.Units.gridUnit * 4
                iconName:    "audio-volume-muted"
                text:        root.emptyTitle
                explanation: root.emptyHint
            }

            delegate: Loader {
                id: entry

                required property int index
                required property var modelData

                width: ListView.view.width
                sourceComponent: modelData.isHeader ? sectionHeader : outputRow

                Component {
                    id: sectionHeader

                    PlasmaExtras.ListSectionHeader {
                        text: entry.modelData.title
                    }
                }

                Component {
                    id: outputRow

                    PlasmaComponents3.ItemDelegate {
                        id: delegate

                        readonly property var  sink:         entry.modelData.sink
                        readonly property bool isEmphasized: hovered || visualFocus

                        // remove the default padding for vertical centering
                        topPadding:    0
                        bottomPadding: 0

                        implicitHeight: root.rowHeight
                        onClicked: root.outputPicked(sink)

                        onIsEmphasizedChanged: {
                            if (isEmphasized) outputList.currentIndex = entry.index;
                            else if (outputList.currentIndex === entry.index) outputList.currentIndex = -1;
                        }

                        contentItem: RowLayout {
                            spacing: Kirigami.Units.largeSpacing

                            PlasmaComponents3.RadioButton {
                                checked:          delegate.sink.default
                                checkable:        false
                                focusPolicy:      Qt.NoFocus
                                Accessible.name:  delegate.sink.description
                                onClicked:        root.outputPicked(delegate.sink)
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Kirigami.Icon {
                                source: root.iconFor(delegate.sink)
                                Layout.preferredWidth:  root.iconSize
                                Layout.preferredHeight: root.iconSize
                            }

                            PlasmaComponents3.Label {
                                text:  delegate.sink.description
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
