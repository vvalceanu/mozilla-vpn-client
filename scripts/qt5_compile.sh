#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

. $(dirname $0)/commons.sh

POSITIONAL=()
JOBS=8
BASE_DIRECTORY="$(pwd)"

helpFunction() {
  print G "Usage:"
  print N "\t$0 <QT_source_folder> <destination_folder> [-j|--jobs <jobs>] [anything else will be use as argument for the QT configure script]"
  print N ""
  exit 0
}

print N "This script compiles Qt5 statically"
print N ""

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  -j | --jobs)
    JOBS="$2"
    shift
    shift
    ;;
  -h | --help)
    helpFunction
    ;;
  *)
    POSITIONAL+=("$1")
    shift
    ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $# -lt 2 ]]; then
  helpFunction
fi

[ -d "$1" ] || die "Unable to find the QT source folder."

cd "$1" || die "Unable to enter into the QT source folder"

shift

PREFIX=$1
shift

printn Y "Cleaning the folder... "
make distclean -j $JOBS &>/dev/null;
print G "done."

LINUX="
  -platform linux-clang \
  -egl \
  -opengl es2 \
  -no-linuxfb \
  -bundled-xcb-xinput \
  -xcb \
"

MACOS="
  -debug-and-release \
  -appstore-compliant \
  -no-feature-qdbus \
  -no-speechd
"

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  print N "Configure for linux"
  PLATFORM=$LINUX
elif [[ "$OSTYPE" == "darwin"* ]]; then
  print N "Configure for darwin"
  PLATFORM=$MACOS

  # remove or review this if we upgrade to a more recent QT version
  print Y "Patching QT header to compile on recent MacOS systems..."
  patch -u -b "qtbase/src/plugins/platforms/cocoa/qiosurfacegraphicsbuffer.h" \
        -i "$BASE_DIRECTORY/macos/qt-for-mac.patch"
  print G "Done"
else
  die "Unsupported platform (yet?)"
fi

print Y "Wait..."
./configure \
  $* \
  --prefix=$PREFIX \
  --recheck-all \
  -opensource \
  -confirm-license \
  -static \
  -strip \
  -silent \
  -no-compile-examples \
  -nomake tests \
  -make libs \
  -no-sql-psql \
  -sql-sqlite \
  -skip qt3d \
  -skip webengine \
  -skip qtmultimedia \
  -skip qtserialport \
  -skip qtsensors \
  -skip qtgamepad \
  -skip qtwebchannel \
  -skip qtandroidextras \
  -feature-imageformat_png \
  -qt-doubleconversion \
  -qt-libpng \
  -qt-zlib \
  -qt-pcre \
  -qt-freetype \
  $PLATFORM || die "Configuration error."

print Y "Compiling..."
make -j $JOBS || die "Make failed"

print Y "Installing..."
make -j $JOBS install || die "Make install failed"

print G "All done!"
