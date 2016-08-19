#!/bin/bash

name=nano
sourceVersion=76a960d73df0461bde66fc25c3e0251b38eeb07f
packageVersion=2.6.3
ext=tar.gz
sourceDir=$ROOT/$name/${name}-${sourceVersion}
echo $sourceDir
# http://git.savannah.gnu.org/cgit/nano.git/snapshot/nano-76a960d73df0461bde66fc25c3e0251b38eeb07f.tar.gz
# https://www.nano-editor.org/dist/v2.6/nano-2.6.3.tar.gz
url=http://git.savannah.gnu.org/cgit/nano.git/snapshot/nano-76a960d73df0461bde66fc25c3e0251b38eeb07f.tar.gz
packDir=$ROOT/$name/${name}_${packageVersion}_iphoneos-arm

armv7dir=$ROOT/$name/armv7
armv7sdir=$ROOT/$name/armv7s
arm64dir=$ROOT/$name/arm64

curl $url -o ${name}.${ext}

tar xf ${name}.${ext}

cd $sourceDir

./autogen.sh

mkdir extra-hdrs
cp $MACSDK/usr/include/{curses.h,ncurses.h,ncurses_dll.h,unctrl.h} extra-hdrs
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
make install DESTDIR=$armv7dir
make clean

export CFLAGS="$ORIGCFLAGS -arch armv7s"

./configure --host armv7s-apple-darwin

make
make install DESTDIR=$armv7sdir
make clean

export CFLAGS="$ORIGCFLAGS -arch arm64"

./configure --host aarch64-apple-darwin

make
make install DESTDIR=$arm64dir
make clean

cd $ROOT/$name

if [ -d "$packDir" ]
then
  sudo rm -r "$packDir"
fi

rsync -ra --exclude .DS_Store $armv7dir/* "$packDir"
rsync -ra -exclude .DS_Store DEBIAN "$packDir"

lipo -create $armv7dir/usr/local/bin/${name} $armv7sdir/usr/local/bin/${name} $arm64dir/usr/local/bin/$name -output $packDir/usr/local/bin/${name}

ldid -S $packDir/usr/local/bin/${name}

if [ -f $packDir/usr/local/share/info/dir ]
then
    sudo rm $packDir/usr/local/share/info/dir
fi

sudo chown -R root:wheel "$packDir"
dpkg-deb --build -Zlzma "$packDir"

mv ${packDir}.deb $ROOT/debs

rm $ROOT/$name/${name}.${ext}
sudo rm -r $packDir
sudo rm -r $sourceDir
rm -r $armv7dir $armv7sdir $arm64dir
