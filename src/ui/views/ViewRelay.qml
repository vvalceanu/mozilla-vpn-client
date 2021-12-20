/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.5
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

import Mozilla.VPN 1.0
import components 0.1

import org.mozilla.Glean 0.24
import telemetry 0.24

VPNFlickable {
    id: relayRoot
    flickContentHeight: relayList.y + relayList.height
    hideScollBarOnStackTransition: true

    VPNIconButton {
        id: iconButton
        objectName: "relayCloseButton"
        onClicked: stackview.pop(StackView.Immediate)
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: VPNTheme.theme.windowMargin / 2
        anchors.leftMargin: VPNTheme.theme.windowMargin / 2
        accessibleName: qsTrId("vpn.connectionInfo.close")

        Image {
            id: backImage

            source: "qrc:/nebula/resources/close-dark.svg"
            sourceSize.width: VPNTheme.theme.iconSize
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: iconButton
        }
    }

    VPNPanel {
        id: vpnPanel
        logoSize: 80
        logo: "qrc:/ui/resources/relay.svg"
        logoTitle: "Relay Addresses"
        logoSubtitle: ""
        anchors.top: parent.top
        anchors.topMargin: (Math.max(window.safeContentHeight * .08, VPNTheme.theme.windowMargin * 2))
        maskImage: true
        isSettingsView: true
    }

    VPNButton {
        id: openWebsite
        objectName: "openWebsite"
        text: "Open website"
        anchors.top: vpnPanel.bottom
        anchors.topMargin: VPNTheme.theme.vSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
            VPN.openLink(VPN.LinkRelay)
        }
    }

    VPNButton {
        id: createButton

        text: "Create"
        anchors.top: openWebsite.bottom
        anchors.bottomMargin: VPNTheme.theme.vSpacing
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
           // TODO
        }
    }

    ColumnLayout {
        id: relayList

        spacing: VPNTheme.theme.listSpacing
        y: VPNTheme.theme.vSpacing + createButton.y + createButton.height

        VPNList {
            spacing: VPNTheme.theme.listSpacing
            model: VPNRelayModel
            width: relayRoot.width

            delegate: RowLayout {
                anchors.leftMargin: VPNTheme.theme.windowMargin / 2
                anchors.rightMargin: VPNTheme.theme.windowMargin / 2
                width: relayList.width

                VPNBoldLabel {
                    id: title
                    text: address
                    width: parent.width - copyIcon.width - deleteIcon.width
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                }

                Item {
                    Layout.fillWidth: true
                }

                VPNIcon {
                    id: copyIcon
                    source: "qrc:/nebula/resources/externalLink.svg"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { VPNRelayModel.copyAddress(idAddress); }
                    }
                }

                VPNIcon {
                    id: deleteIcon
                    source: "qrc:/nebula/resources/delete.svg"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { VPNRelayModel.deleteAddress(idAddress); }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                Accessible.ignored: true
            }

        }
    }

    Component.onCompleted: VPNRelayModel.initialize()
}
