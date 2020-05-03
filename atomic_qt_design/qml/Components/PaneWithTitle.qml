import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

import "../Constants"

Column {
    id: column
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    spacing: Style.paneTitleOffset


    property string title
    property alias content: inner_space.sourceComponent
    property string color: Style.colorTheme6
    DefaultText {
        text: API.get().empty_string + (title)
    }

    Pane {
        id: pane

        background: FloatingBackground {
            color: column.color
        }

        Loader {
            id: inner_space
        }
    }
}





/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
