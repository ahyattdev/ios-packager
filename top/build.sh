#!/bin/bash

version=3.7
sourceDir=top-${version}
url=http://www.unixtop.org/dist/top-${version}.tar.gz

packDir=top_${version}_iphoneos-arm

curl $url -o top.tar.gz

tar xf top.tar.gz

cd $sourceDir

mkdir -p extra-hdrs/sys

cp ~/Applications/xc8b4.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/{termcap.h,ncurses_dll.h} extra-hdrs

cp ~/Applications/xc8b4.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/dkstat.h extra-hdrs/sys

curl http://opensource.apple.com/source/Libc/Libc-339/include/kvm.h?txt -o extra-hdrs/kvm.h

export CC=clang
export CXX=clang++
export ORIGCFLAGS="-isysroot $IOSSDK -I`pwd`/extra-hdrs"

export CFLAGS="$ORIGCFLAGS -arch armv7"

./configure --host armv7-apple-darwin --with-module=macosx

make
make install DESTDIR=../armv7
make clean

export CFLAGS="$ORIGCFLAGS -arch armv7s"

./configure --host armv7s-apple-darwin --with-module=macosx

make
make install DESTDIR=../armv7s
make clean

cd ..

if [ -d "$packDir" ]
then
  sudo rm -r "$packDir"
fi

rsync -ra --exclude .DS_Store armv7/* "$packDir"
rsync -ra -exclude .DS_Store DEBIAN "$packDir"

lipo -create armv7/usr/local/bin/top armv7s/usr/local/bin/top -output $packDir/usr/local/bin/top

ldid -S $packDir/usr/local/bin/top

sudo chown -R root:wheel "$packDir"
dpkg-deb --build -Zlzma "$packDir"

mv ${packDir}.deb ../debs

rm top.tar.gz
sudo rm -r $packDir
sudo rm -r $sourceDir
rm -r armv7 armv7s
