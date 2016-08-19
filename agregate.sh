#!/bin/bash

ROOT=`realpath $0`
export ROOT=`dirname $ROOT`
mkdir -p debs

allPacakges="nano"
function build_package {
  package=$1
  cd "$package"
  ./build.sh
  cd ..
}

if [ -z ${1+x} ]; then
  for package in "$allPacakges"
  do
    build_package $package
  done
else
    for package in "$@"
    do
      if [ -d "$package" ]; then
        echo "Building: $package"
        build_package "$package"
      else
        echo "Package not found: $package"
      fi
    done
fi
