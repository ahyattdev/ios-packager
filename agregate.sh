#!/bin/bash
set -e

export DEB_DIR="`pwd`/debs"
export POOLROOT="`pwd`/poolroot"
export POOLLIB="$POOLROOT/usr/lib"
export POOLINC="$POOLROOT/usr/include"

mkdir -p "$DEB_DIR"
mkdir -p "$POOLROOT"

export JOBS=4

export SDK=`xcrun -sdk iphoneos --show-sdk-path`
export MACSDK=`xcrun -sdk macosx --show-sdk-path`
export ARCHS="-arch armv7 -arch armv7s -arch arm64"

export MAINTAINER="Andrew Hyatt <ahyattdev@icloud.com"

export ARCHITECTURE=iphoneos-arm

export GPG_ERROR_PREFIX="`pwd`/libgpg-error/libgpg-error_1.26_iphoneos-arm/usr"

allPacakges="man-db nano texinfo libiconv apt-file groff"

function recursive_ldid() {
    find "$1" -type f -perm +x -exec ldid -S {} \;
}
export -f recursive_ldid

function build_package {
  package=$1
  pushd "$package"
  ./build.sh
  popd
}

if [ $1 == clean ]
then
    exec rm -r "$DEB_DIR"
fi

if [ -z $1 ]; then
  for package in "$allPacakges"
  do
    build_package $package
  done
else
    for package in "$@"
    do
        build_package $package
    done
fi
