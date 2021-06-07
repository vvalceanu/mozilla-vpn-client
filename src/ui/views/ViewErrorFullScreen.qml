/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.5
import QtQuick.Layouts 1.14
import Mozilla.VPN 1.0
import "../components"
import "../themes/themes.js" as Theme
import "/glean/load.js" as Glean



VPNFlickable {

    property var headlineText
    property var errorMessage: ""
    property var errorMessage2: ""
    property var buttonText
    property var buttonObjectName
    property var buttonOnClick
    property var signOffLinkVisible: false
    property var getHelpLinkVisible: false
    property var statusLinkVisible: false

    id: vpnFlickable

    Component.onCompleted: {
        flickContentHeight = col.childrenRect.height
    }

    VPNHeaderLink {
        id: headerLink
        objectName: "getHelpLink"

        labelText: qsTrId("vpn.main.getHelp")
        onClicked: stackview.push(getHelpComponent)
    }

    Component {
        id: getHelpComponent

        VPNGetHelp {
            isSettingsView: false
        }
    }

    ColumnLayout {
        id: col

        anchors.topMargin: Theme.windowMargin * 4
        anchors.fill: parent
        spacing: 32

        VPNHeadline {
            id: headline

            text: headlineText
            width: undefined
            Layout.fillWidth: true
            Layout.leftMargin: Theme.windowMargin * 2
            Layout.rightMargin: Theme.windowMargin * 2
        }

        ColumnLayout {
            spacing: 24
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: Theme.windowMargin * 2
            Layout.rightMargin: Theme.windowMargin * 2

            Rectangle {
                id: warningIconWrapper

                Layout.preferredHeight: 48
                Layout.preferredWidth: 48
                Layout.alignment: Qt.AlignHCenter
                color: Theme.red
                radius: height / 2

                Image {
                    source: "../resources/warning-white.svg"
                    antialiasing: true
                    sourceSize.height: 20
                    sourceSize.width: 20
                    anchors.centerIn: parent
                }

            }

            ColumnLayout {
                spacing: Theme.windowMargin

                VPNTextBlock {
                    id: copyBlock1
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSize
                    lineHeight: 22
                    text: errorMessage
                    width: undefined
                    Layout.fillWidth: true
                    Layout.maximumWidth: Theme.maxHorizontalContentWidth - (Theme.windowMargin * 6)

                }

                VPNTextBlock {
                    id: copyBlock2

                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSize
                    lineHeight: copyBlock1.lineHeight
                    text: errorMessage2
                    Layout.fillWidth: true
                    Layout.maximumWidth: Theme.maxHorizontalContentWidth - (Theme.windowMargin * 6)
                }

                VPNLinkButton {
                    //% "Check outage updates"
                    labelText: qsTrId("vpn.errors.checkOutageUpdates")
                    onClicked: VPN.openLink("https://status.vpn.mozilla.org")
                    visible: statusLinkVisible
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.maximumWidth: Theme.maxHorizontalContentWidth - (Theme.windowMargin * 6)
                }
            }
        }

        Column {
            spacing: Theme.windowMargin * 1.5
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Layout.fillWidth: true

            VPNButton {
                id: btn

                objectName: buttonObjectName
                text: buttonText
                loaderVisible: false
                onClicked: buttonOnClick()
                anchors.horizontalCenter: parent.horizontalCenter
            }

            VPNSignOut {
                id: signOff

                visible: signOffLinkVisible
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: undefined
                onClicked: {
                    VPNController.logout();
                }
            }
        }

        VPNVerticalSpacer {
            Layout.preferredHeight: fullscreenRequired() ? Theme.windowMargin * 2 : 1
        }
    }
}
