#!/bin/bash

export DEB_DIR=debs
mkdir -p "$DEB_DIR"

export SDK=`xcrun -sdk iphoneos --show-sdk-path`
export ARCHS="-arch armv7 -arch armv7s -arch arm64"

export MAINTAINER="Andrew Hyatt <ahyattdev@icloud.com"

export ARCHITECTURE=iphoneos-arm

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
