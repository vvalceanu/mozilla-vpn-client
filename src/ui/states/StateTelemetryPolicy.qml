/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.5
import QtQuick.Controls 2.14
import QtGraphicalEffects 1.14
import QtQuick.Layouts 1.14
import Mozilla.VPN 1.0
import "../themes/themes.js" as Theme
import "../components"

VPNFlickable {
    id: vpnFlickable

    flickContentHeight: column.y + column.implicitHeight
    Component.onCompleted: {
        fade.start();
    }

    VPNPanel {
        id: panel
        logo: "../resources/updateRecommended.svg"
        logoTitle: qsTrId("vpn.settings.dataCollection")
        //% "We strive to provide you with choices and collect only the technical data we need to improve Mozilla VPN. Sharing data with Mozilla is optional."
        logoSubtitle: qsTrId("vpn.telemetryPolicy.telemetryDisclaimer")
        anchors.top: parent.top
        anchors.topMargin: (Math.max(window.safeContentHeight * .08, Theme.windowMargin * 2))
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.leftMargin: Theme.windowMargin
        anchors.rightMargin: Theme.windowMargin
        anchors.topMargin: panel.height + panel.y
        spacing: 0


        VPNVerticalSpacer {
            Layout.preferredHeight: (Math.max(window.safeContentHeight * .08, Theme.windowMargin))
        }


        ColumnLayout {
            spacing: Theme.windowMargin
            Layout.maximumWidth: Theme.maxHorizontalContentWidth
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Layout.leftMargin: Theme.windowMargin * 2
            Layout.rightMargin: Theme.windowMargin * 2
            Layout.fillHeight: true

            VPNSubtitle  {
                id: logoSubtitle
                //% "Allow Mozilla VPN to send technical data to Mozilla?"
                text: qsTrId("vpn.telemetryPolicy.allowMozillaToSendData")
                width: undefined
                Layout.fillWidth: true
            }

            VPNButton {
                id: button
                objectName: "telemetryPolicyButton"
                //% "Allow on this device"
                text: qsTrId("vpn.telemetryPolicy.allowOnThisDevice")
                width: undefined
                height: undefined
                Layout.fillWidth: true
                Layout.minimumHeight: Theme.rowHeight
                onClicked: {
                    VPNSettings.gleanEnabled = true;
                    VPN.telemetryPolicyCompleted();
                }
            }

            VPNLinkButton {
                id: linkBtn
                objectName: "declineTelemetryLink"
                //% "Don’t allow"
                labelText: qsTrId("vpn.telemetryPolicy.doNotAllow")
                Layout.fillWidth: true
                onClicked: {
                    VPNSettings.gleanEnabled = false;
                    VPN.telemetryPolicyCompleted();
                }
            }

            VPNVerticalSpacer {
                Layout.preferredHeight: 1
                Layout.fillHeight: true
                Layout.maximumHeight: Theme.windowMargin
            }

            ColumnLayout {
                spacing: 0
                Layout.fillHeight: true

                VPNSubtitle {
                    //% "Learn more about what data Mozilla collects and how it’s used."
                    text: qsTrId("vpn.telemetryPolicy.learnMoreAboutData")
                    Layout.fillWidth: true
                    width: undefined
                }

                VPNLinkButton {
                    objectName: "privacyLink"
                    //% "Mozilla VPN Privacy Notice"
                    labelText: qsTrId("vpn.telemetryPolicy.MozillaVPNPrivacyNotice")
                    onClicked: VPN.openLink(VPN.LinkPrivacyNotice)
                    Layout.fillWidth: true
                }

                VPNVerticalSpacer {
                    Layout.preferredHeight: Theme.windowMargin * 2
                }
            }

        }

    }



    PropertyAnimation on opacity {
        id: fade

        from: 0
        to: 1
        duration: 300
    }

}
