import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume

import "../tools/deviceIcons.js" as DeviceIcons

PlasmoidItem {
    id: root

    readonly property int actionSwitchOutput: 0
    readonly property int wheelDelayMs:       250

    property var  sinks: []
    property var  outputActionList: []
    property real lastWheelMs:      0

    readonly property var deviceOrder:     Plasmoid.configuration.deviceOrder
    readonly property var excludedDevices: Plasmoid.configuration.excludedDevices

    readonly property var deviceIcons: parseDeviceIcons(Plasmoid.configuration.deviceIcons)

    readonly property var rotationSinks: sortByDeviceOrder(sinks).filter(sink => !excludedDevices.includes(sink.name))
    readonly property var skippedSinks:  sortByDeviceOrder(sinks).filter(sink => excludedDevices.includes(sink.name))
    readonly property var currentSink:   sinks.find(sink => sink.default) ?? null

    readonly property string emptyTitle: i18n("No output devices")
    readonly property string emptyHint:  i18n("Connect speakers or headphones and they will show up here")

    readonly property string iconName: currentSink ? iconFor(currentSink) : Plasmoid.icon

    function parseDeviceIcons(json: string): var {
        try {
            return JSON.parse(json);
        } catch (error) {
            console.warn("audioswitch: ignoring invalid deviceIcons setting:", error.message);
            return {};
        }
    }

    // use the form factor icon, then a fallback
    function systemIconFor(sink: var): string {
        return DeviceIcons.systemIconFor(sink.iconName, AudioIcon.forFormFactor(sink.formFactor));
    }

    function iconFor(sink: var): string {
        return deviceIcons[sink.name] || systemIconFor(sink);
    }

    // devices missing from the saved order go last
    function sortByDeviceOrder(sinkList: var): var {
        const rankOf = sink => {
            const position = deviceOrder.indexOf(sink.name);
            return position === -1 ? deviceOrder.length : position;
        };
        return sinkList.slice().sort((first, second) => rankOf(first) - rankOf(second));
    }

    function rotateOutput(step: int): void {
        const count = rotationSinks.length;
        if (count === 0) return;
        const currentPosition   = rotationSinks.findIndex(sink => sink.default);
        const isOutsideRotation = currentPosition === -1;
        const nextPosition      = isOutsideRotation ? (step > 0 ? 0 : count - 1) : (currentPosition + step + count) % count;
        rotationSinks[nextPosition].default = true;
    }

    function refreshOutputActions(): void {
        const actions = [];
        for (let i = 0; i < outputActions.count; i++) actions.push(outputActions.objectAt(i));
        outputActionList = actions;
    }

    function toggleList(): void {
        expanded = !expanded;
    }

    function runClickAction(action: int): void {
        const isSwitchOutput = action === actionSwitchOutput;
        if (isSwitchOutput) rotateOutput(1);
        else toggleList();
    }

    function handleClick(): void {
        runClickAction(Plasmoid.configuration.leftClickAction);
    }

    function handleMiddleClick(): void {
        runClickAction(Plasmoid.configuration.middleClickAction);
    }

    function handleWheel(wheel: var): void {
        // debounce scroll events
        const now = Date.now();
        if (now - lastWheelMs < wheelDelayMs) return;
        lastWheelMs = now;
        rotateOutput(wheel.angleDelta.y > 0 ? 1 : -1);
    }

    // each delegate registers its sink, keeping the list in sync
    Repeater {
        model: SinkModel {}
        delegate: Item {
            required property var model
            readonly property var sink: model.PulseObject

            Component.onCompleted:   root.sinks = [...root.sinks, sink]
            Component.onDestruction: root.sinks = root.sinks.filter(other => other !== sink)
        }
    }

    PlasmaCore.ActionGroup {
        id: outputActionGroup
    }

    Instantiator {
        id: outputActions

        model: root.sortByDeviceOrder(root.sinks)
        delegate: PlasmaCore.Action {
            required property var modelData

            text:        modelData.description
            icon.name:   root.iconFor(modelData)
            actionGroup: outputActionGroup
            checkable:   true
            checked:     modelData.default
            onTriggered: modelData.default = true
        }

        onObjectAdded:   Qt.callLater(root.refreshOutputActions)
        onObjectRemoved: Qt.callLater(root.refreshOutputActions)
    }

    Connections {
        target: Plasmoid
        function onActivated(): void {
            root.rotateOutput(1);
            // the key shortcut only rotates
            // limit: Plasma expands the widget on activation anyway
            // shortcut: this also closes the list if it was open, upgrade if that gets in the way
            Qt.callLater(() => root.expanded = false);
        }
    }

    preferredRepresentation:   compactRepresentation
    activationTogglesExpanded: false

    Plasmoid.contextualActions: outputActionList

    toolTipMainText: Plasmoid.title
    toolTipSubText:  currentSink?.description ?? emptyTitle

    compactRepresentation: Component {
        Kirigami.Icon {
            readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

            Layout.preferredWidth:  isVertical ? width : height
            Layout.preferredHeight: isVertical ? width : height

            source: root.iconName
            active: mouseArea.containsMouse || activeFocus

            activeFocusOnTab:         true
            Accessible.name:          Plasmoid.title
            Accessible.description:   root.toolTipSubText
            Accessible.role:          Accessible.Button
            Accessible.onPressAction: root.handleClick()

            Keys.onPressed: event => {
                const isActivationKey = [Qt.Key_Space, Qt.Key_Enter, Qt.Key_Return, Qt.Key_Select].includes(event.key);
                if (!isActivationKey) return;
                root.handleClick();
                event.accepted = true;
            }

            MouseArea {
                id: mouseArea
                anchors.fill:    parent
                hoverEnabled:    true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: mouse => {
                    const isMiddleClick = mouse.button === Qt.MiddleButton;
                    if (isMiddleClick) root.handleMiddleClick();
                    else root.handleClick();
                }
                onWheel: wheel => root.handleWheel(wheel)
            }
        }
    }

    fullRepresentation: OutputList {
        enabledOutputs: root.rotationSinks
        skippedOutputs: root.skippedSinks
        iconFor:        root.iconFor
        emptyTitle:     root.emptyTitle
        emptyHint:      root.emptyHint
        isPinned:       !root.hideOnWindowDeactivate

        onOutputPicked:      sink => sink.default = true
        onSettingsRequested: Plasmoid.internalAction("configure")?.trigger()
        onPinToggled:        shouldStayOpen => root.hideOnWindowDeactivate = !shouldStayOpen
    }
}
