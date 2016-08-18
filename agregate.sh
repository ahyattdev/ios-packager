#!/bin/bash

mkdir -p debs

allPacakges="screen vile"
function build_package {
  package=$1
  cd "$package"
  ./build.sh
  cd ..
}

if [ -z ${VAR+x} ]; then
  for package in "$allPacakges"
  do
    build_package $package
  done
fi

for package in "$@"
do
  if [ -d "$package" ]; then
    echo "Building: $package"
    build_package "$package"
  else
    echo "Package not found: $package"
  fi
done
