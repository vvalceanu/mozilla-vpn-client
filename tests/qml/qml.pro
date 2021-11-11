# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
TEMPLATE = app
TARGET = qml_tests

QT += charts
QT += network
QT += networkauth
QT += qml
QT += quick
QT += websockets
QT += xml

CONFIG += warn_on qmltestcase

DEFINES += QT_DEPRECATED_WARNINGS
DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x050F00

DEFINES += MVPN_DUMMY
# Sets up app and build id which we test for in test_VPNAboutUs
DEFINES += APP_VERSION=\\\"QMLTest_AppVersion\\\"
DEFINES += BUILD_ID=\\\"QMLTest_BuildID\\\"

RESOURCES += \
    ../../src/ui/compatQt5.qrc \
    ../../src/ui/compatQt6.qrc \
    ../../src/ui/components.qrc \
    ../../src/ui/resources.qrc \
    ../../src/ui/themes.qrc \
    ../../src/ui/ui.qrc \

INCLUDEPATH += \
    . \
    ../../glean/telemetry \
    ../../src \
    ../../src/hacl-star \
    ../../src/hacl-star/kremlin \
    ../../src/hacl-star/kremlin/minimal \
    ../../translations/generated \

SOURCES += \
    main.cpp \
    mocmozillavpn.cpp \
    ../../src/apppermission.cpp \
    ../../src/authenticationlistener.cpp \
    ../../src/authenticationinapp/authenticationinapp.cpp \
    ../../src/authenticationinapp/authenticationinapplistener.cpp \
    ../../src/authenticationinapp/incrementaldecoder.cpp \
    ../../src/captiveportal/captiveportal.cpp \
    ../../src/captiveportal/captiveportaldetection.cpp \
    ../../src/captiveportal/captiveportaldetectionimpl.cpp \
    ../../src/captiveportal/captiveportalmonitor.cpp \
    ../../src/captiveportal/captiveportalnotifier.cpp \
    ../../src/captiveportal/captiveportalrequest.cpp \
    ../../src/captiveportal/captiveportalmultirequest.cpp \
    ../../src/closeeventhandler.cpp \
    ../../src/collator.cpp \
    ../../src/command.cpp \
    ../../src/commandlineparser.cpp \
    ../../src/commands/commandactivate.cpp \
    ../../src/commands/commanddeactivate.cpp \
    ../../src/commands/commanddevice.cpp \
    ../../src/commands/commandlogin.cpp \
    ../../src/commands/commandlogout.cpp \
    ../../src/commands/commandselect.cpp \
    ../../src/commands/commandservers.cpp \
    ../../src/commands/commandstatus.cpp \
    ../../src/commands/commandui.cpp \
    ../../src/connectioncheck.cpp \
    ../../src/connectiondataholder.cpp \
    ../../src/connectionhealth.cpp \
    ../../src/constants.cpp \
    ../../src/controller.cpp \
    ../../src/cryptosettings.cpp \
    ../../src/curve25519.cpp \
    ../../src/dnshelper.cpp \
    ../../src/errorhandler.cpp \
    ../../src/featurelist.cpp \
    ../../src/filterproxymodel.cpp \
    ../../src/fontloader.cpp \
    ../../src/hacl-star/Hacl_Chacha20.c \
    ../../src/hacl-star/Hacl_Chacha20Poly1305_32.c \
    ../../src/hacl-star/Hacl_Curve25519_51.c \
    ../../src/hacl-star/Hacl_Poly1305_32.c \
    ../../src/hawkauth.cpp \
    ../../src/hkdf.cpp \
    ../../src/iaphandler.cpp \
    ../../src/inspector/inspectorwebsocketconnection.cpp \
    ../../src/inspector/inspectorwebsocketserver.cpp \
    ../../src/ipaddress.cpp \
    ../../src/ipaddressrange.cpp \
    ../../src/ipfinder.cpp \
    ../../src/l18nstringsimpl.cpp \
    ../../src/leakdetector.cpp \
    ../../src/localizer.cpp \
    ../../src/logger.cpp \
    ../../src/loghandler.cpp \
    ../../src/logoutobserver.cpp \
    ../../src/models/device.cpp \
    ../../src/models/devicemodel.cpp \
    ../../src/models/feature.cpp \
    ../../src/models/feedbackcategorymodel.cpp \
    ../../src/models/helpmodel.cpp \
    ../../src/models/keys.cpp \
    ../../src/models/licensemodel.cpp \
    ../../src/models/server.cpp \
    ../../src/models/servercity.cpp \
    ../../src/models/servercountry.cpp \
    ../../src/models/servercountrymodel.cpp \
    ../../src/models/serverdata.cpp \
    ../../src/models/supportcategorymodel.cpp \
    ../../src/models/survey.cpp \
    ../../src/models/surveymodel.cpp \
    ../../src/models/user.cpp \
    ../../src/models/whatsnewmodel.cpp \
    #../../src/mozillavpn.cpp \
    ../../src/networkmanager.cpp \
    ../../src/networkrequest.cpp \
    ../../src/networkwatcher.cpp \
    ../../src/notificationhandler.cpp \
    ../../src/pinghelper.cpp \
    ../../src/pingsender.cpp \
    ../../src/platforms/dummy/dummyapplistprovider.cpp \
    ../../src/platforms/dummy/dummycontroller.cpp \
    ../../src/platforms/dummy/dummycryptosettings.cpp \
    ../../src/platforms/dummy/dummyiaphandler.cpp \
    ../../src/platforms/dummy/dummynetworkwatcher.cpp \
    ../../src/platforms/dummy/dummypingsender.cpp \
    ../../src/qmlengineholder.cpp \
    ../../src/releasemonitor.cpp \
    ../../src/rfc/rfc1112.cpp \
    ../../src/rfc/rfc1918.cpp \
    ../../src/rfc/rfc4193.cpp \
    ../../src/rfc/rfc4291.cpp \
    ../../src/rfc/rfc5735.cpp \
    ../../src/serveri18n.cpp \
    ../../src/settingsholder.cpp \
    ../../src/simplenetworkmanager.cpp \
    ../../src/statusicon.cpp \
    ../../src/systemtraynotificationhandler.cpp \
    ../../src/tasks/accountandservers/taskaccountandservers.cpp \
    ../../src/tasks/adddevice/taskadddevice.cpp \
    ../../src/tasks/authenticate/desktopauthenticationlistener.cpp \
    ../../src/tasks/authenticate/taskauthenticate.cpp \
    ../../src/tasks/captiveportallookup/taskcaptiveportallookup.cpp \
    ../../src/tasks/getfeaturelist/taskgetfeaturelist.cpp \
    ../../src/tasks/controlleraction/taskcontrolleraction.cpp \
    ../../src/tasks/createsupportticket/taskcreatesupportticket.cpp \
    ../../src/tasks/function/taskfunction.cpp \
    ../../src/tasks/heartbeat/taskheartbeat.cpp \
    ../../src/tasks/products/taskproducts.cpp \
    ../../src/tasks/removedevice/taskremovedevice.cpp \
    ../../src/tasks/sendfeedback/tasksendfeedback.cpp \
    ../../src/tasks/surveydata/tasksurveydata.cpp \
    ../../src/taskscheduler.cpp \
    ../../src/timercontroller.cpp \
    ../../src/timersingleshot.cpp \
    ../../src/update/updater.cpp \
    ../../src/update/versionapi.cpp \
    ../../src/urlopener.cpp


HEADERS += \
    ../../src/appimageprovider.h \
    ../../src/apppermission.h \
    ../../src/applistprovider.h \
    ../../src/authenticationlistener.h \
    ../../src/authenticationinapp/authenticationinapp.h \
    ../../src/authenticationinapp/authenticationinapplistener.h \
    ../../src/authenticationinapp/incrementaldecoder.h \
    ../../src/bigintipv6addr.h \
    ../../src/captiveportal/captiveportal.h \
    ../../src/captiveportal/captiveportaldetection.h \
    ../../src/captiveportal/captiveportaldetectionimpl.h \
    ../../src/captiveportal/captiveportalmonitor.h \
    ../../src/captiveportal/captiveportalnotifier.h \
    ../../src/captiveportal/captiveportalrequest.h \
    ../../src/captiveportal/captiveportalmultirequest.h \
    ../../src/captiveportal/captiveportalresult.h \
    ../../src/closeeventhandler.h \
    ../../src/collator.h \
    ../../src/command.h \
    ../../src/commandlineparser.h \
    ../../src/commands/commandactivate.h \
    ../../src/commands/commanddeactivate.h \
    ../../src/commands/commanddevice.h \
    ../../src/commands/commandlogin.h \
    ../../src/commands/commandlogout.h \
    ../../src/commands/commandselect.h \
    ../../src/commands/commandservers.h \
    ../../src/commands/commandstatus.h \
    ../../src/commands/commandui.h \
    ../../src/connectioncheck.h \
    ../../src/connectiondataholder.h \
    ../../src/connectionhealth.h \
    ../../src/constants.h \
    ../../src/controller.h \
    ../../src/controllerimpl.h \
    ../../src/cryptosettings.h \
    ../../src/curve25519.h \
    ../../src/dnshelper.h \
    ../../src/errorhandler.h \
    ../../src/featurelist.h \
    ../../src/features/featureappreview.h \
    ../../src/features/featurecaptiveportal.h \
    ../../src/features/featurecustomdns.h \
    ../../src/features/featureinappaccountCreate.h \
    ../../src/features/featureinappauth.h \
    ../../src/features/featureinapppurchase.h \
    ../../src/features/featurelocalareaaccess.h \
    ../../src/features/featuremultihop.h \
    ../../src/features/featurenotificationcontrol.h \
    ../../src/features/featuresharelogs.h \
    ../../src/features/featuresplittunnel.h \
    ../../src/features/featurestartonboot.h \
    ../../src/features/featureuniqueid.h \
    ../../src/features/featureunsecurednetworknotification.h \
    ../../src/filterproxymodel.h \
    ../../src/fontloader.h \
    ../../src/hawkauth.h \
    ../../src/hkdf.h \
    ../../src/iaphandler.h \
    ../../src/inspector/inspectorwebsocketconnection.h \
    ../../src/inspector/inspectorwebsocketserver.h \
    ../../src/ipaddress.h \
    ../../src/ipaddressrange.h \
    ../../src/ipfinder.h \
    ../../src/leakdetector.h \
    ../../src/localizer.h \
    ../../src/logger.h \
    ../../src/loghandler.h \
    ../../src/logoutobserver.h \
    ../../src/models/device.h \
    ../../src/models/devicemodel.h \
    ../../src/models/feature.h \
    ../../src/models/feedbackcategorymodel.h \
    ../../src/models/helpmodel.h \
    ../../src/models/keys.h \
    ../../src/models/licensemodel.h \
    ../../src/models/server.h \
    ../../src/models/servercity.h \
    ../../src/models/servercountry.h \
    ../../src/models/servercountrymodel.h \
    ../../src/models/serverdata.h \
    ../../src/models/supportcategorymodel.h \
    ../../src/models/survey.h \
    ../../src/models/surveymodel.h \
    ../../src/models/user.h \
    ../../src/models/whatsnewmodel.h \
    ../../src/mozillavpn.h \
    ../../src/networkmanager.h \
    ../../src/networkrequest.h \
    ../../src/networkwatcher.h \
    ../../src/networkwatcherimpl.h \
    ../../src/notificationhandler.h \
    ../../src/pinghelper.h \
    ../../src/pingsender.h \
    ../../src/platforms/dummy/dummyapplistprovider.h \
    ../../src/platforms/dummy/dummycontroller.h \
    ../../src/platforms/dummy/dummyiaphandler.h \
    ../../src/platforms/dummy/dummynetworkwatcher.h \
    ../../src/platforms/dummy/dummypingsender.h \
    ../../src/qmlengineholder.h \
    ../../src/releasemonitor.h \
    ../../src/rfc/rfc1112.h \
    ../../src/rfc/rfc1918.h \
    ../../src/rfc/rfc4193.h \
    ../../src/rfc/rfc4291.h \
    ../../src/rfc/rfc5735.h \
    ../../src/serveri18n.h \
    ../../src/settingsholder.h \
    ../../src/simplenetworkmanager.h \
    ../../src/statusicon.h \
    ../../src/systemtraynotificationhandler.h \
    ../../src/task.h \
    ../../src/tasks/accountandservers/taskaccountandservers.h \
    ../../src/tasks/adddevice/taskadddevice.h \
    ../../src/tasks/authenticate/taskauthenticate.h \
    ../../src/tasks/authenticate/desktopauthenticationlistener.h \
    ../../src/tasks/captiveportallookup/taskcaptiveportallookup.h \
    ../../src/tasks/getfeaturelist/taskgetfeaturelist.h \
    ../../src/tasks/controlleraction/taskcontrolleraction.h \
    ../../src/tasks/createsupportticket/taskcreatesupportticket.h \
    ../../src/tasks/function/taskfunction.h \
    ../../src/tasks/heartbeat/taskheartbeat.h \
    ../../src/tasks/products/taskproducts.h \
    ../../src/tasks/removedevice/taskremovedevice.h \
    ../../src/tasks/sendfeedback/tasksendfeedback.h \
    ../../src/tasks/surveydata/tasksurveydata.h \
    ../../src/taskscheduler.h \
    ../../src/timercontroller.h \
    ../../src/timersingleshot.h \
    ../../src/update/updater.h \
    ../../src/update/versionapi.h \
    ../../src/urlopener.h

# Signal handling for unix platforms
unix {
    SOURCES += ../../src/signalhandler.cpp
    HEADERS += ../../src/signalhandler.h
}

exists($$PWD/../../glean/telemetry/gleansample.h) {
    RESOURCES += $$PWD/../../glean/glean.qrc
    #HEADERS += $$PWD/../../glean/telemetry/gleansample.h
} else {
    error(Glean generated files are missing. Please run `./scripts/generate_glean.py`.)
}
exists($$PWD/../../translations/generated/l18nstrings.h) {
    SOURCES += $$PWD/../../translations/generated/l18nstrings_p.cpp
    HEADERS += $$PWD/../../translations/generated/l18nstrings.h
} else {
    error("Localization files are missing. Please run `./scripts/importLanguages.py`.")
}

OBJECTS_DIR = .obj
MOC_DIR = .moc
