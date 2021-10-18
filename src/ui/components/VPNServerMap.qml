/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.5
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQml.Models 2.2
import QtLocation 5.6
import QtPositioning 5.11

import Mozilla.VPN 1.0
import components 0.1
import components.forms 0.1
import themes 0.1

FocusScope {
    id: focusScope

    property real listOffset: (Theme.menuHeight * 2)
    property bool showRecentConnections: false
    property var currentServer

    Layout.fillWidth: true
    Layout.fillHeight: true
    Accessible.name: menu.title
    Accessible.role: Accessible.List

    Plugin {
        id: mapPlugin
        name: "osm"
    }

    Map {
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate(VPNCurrentServer.exitLatitude(), VPNCurrentServer.exitLongitude())
        zoomLevel: 5

        MapItemView {
           model: VPNServerCountryMapModel
           delegate: MapQuickItem {
               coordinate: QtPositioning.coordinate(latitude, longitude)

               anchorPoint.x: image.width * 0.5
               anchorPoint.y: image.height

               sourceItem: Column {
                   Image {
                       id: image
                       source: VPNCurrentServer.exitCountryCode === countryCode &&
                               VPNCurrentServer.exitCityName === name ? "qrc:/ui/resources/logo-on.png" : "qrc:/ui/resources/logo-generic.png"
                       width: 30
                       height: 30
                   }
                   Text {
                       text: name
                       font.bold: VPNCurrentServer.exitCountryCode === countryCode &&
                                  VPNCurrentServer.exitCityName === name
                   }
               }

               MouseArea {
                   anchors.fill: parent
                   onClicked: {
                        VPNController.changeServer(countryCode, name);
                        return stackview.pop();
                   }
               }
           }
       }
   }
}
