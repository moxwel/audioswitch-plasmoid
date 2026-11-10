import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_leftClickAction:   leftClickComboBox.currentIndex
    property alias cfg_middleClickAction: middleClickComboBox.currentIndex

    property int cfg_leftClickActionDefault
    property int cfg_middleClickActionDefault

    readonly property var actionNames: [i18n("Switch output"), i18n("Menu")]

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: leftClickComboBox
            Kirigami.FormData.label: i18n("Left click:")
            model: root.actionNames
        }

        QQC2.ComboBox {
            id: middleClickComboBox
            Kirigami.FormData.label: i18n("Middle click:")
            model: root.actionNames
        }
    }
}
