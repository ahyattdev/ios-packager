#!/bin/bash

name=screen
sourceVersion=4.4.0
packageVersion=4.4.0
ext=tar.gz
sourceDir=${name}-${sourceVersion}
url=http://ftp.gnu.org/gnu/screen/${name}-${sourceVersion}.${ext}
packDir=${name}_${packageVersion}_iphoneos-arm

curl $url -o ${name}.${ext}

tar xf ${name}.${ext}

cd $sourceDir

#mkdir -p extra-hdrs/sys

#cp ~/Applications/xc8b4.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/{termcap.h,ncurses_dll.h} extra-hdrs

#cp ~/Applications/xc8b4.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/dkstat.h extra-hdrs/sys

#curl http://opensource.apple.com/source/Libc/Libc-339/include/kvm.h?txt -o extra-hdrs/kvm.h

export CC=clang
export CXX=clang++
export ORIGCFLAGS="-isysroot $IOSSDK -I`pwd`/extra-hdrs"

export CFLAGS="$ORIGCFLAGS -arch armv7"

./configure --host armv7-apple-darwin

make
make install DESTDIR=../armv7
make clean

export CFLAGS="$ORIGCFLAGS -arch armv7s"

./configure --host armv7s-apple-darwin

make
make install DESTDIR=../armv7s
make clean

export CFLAGS="$ORIGCFLAGS -arch arm64"

./configure --host aarch64-apple-darwin

make
make install DESTDIR=../arm64
make clean

cd ..

if [ -d "$packDir" ]
then
  sudo rm -r "$packDir"
fi

rsync -ra --exclude .DS_Store armv7/* "$packDir"
rsync -ra -exclude .DS_Store DEBIAN "$packDir"

#lipo -create armv7/usr/local/bin/${name} armv7s/usr/local/bin/${name} -output $packDir/usr/local/bin/${name}

#ldid -S $packDir/usr/local/bin/${name}

sudo chown -R root:wheel "$packDir"
dpkg-deb --build -Zlzma "$packDir"

mv ${packDir}.deb ../debs

rm ${name}.${ext}
sudo rm -r $packDir
sudo rm -r $sourceDir
rm -r armv7 armv7s arm64
