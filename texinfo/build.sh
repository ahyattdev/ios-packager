#!/bin/bash

name=texinfo
sourceVersion=6.1
packageVersion=6.1
ext=tar.gz
sourceDir=$ROOT/$name/${name}-${sourceVersion}
echo $sourceDir
url=http://ftp.gnu.org/gnu/$name/$name-$sourceVersion.$ext
packDir=$ROOT/$name/${name}_${packageVersion}_iphoneos-arm

armv7dir=$ROOT/$name/armv7
armv7sdir=$ROOT/$name/armv7s
arm64dir=$ROOT/$name/arm64

curl $url -o ${name}.${ext}

tar xf ${name}.${ext}

cd $sourceDir

mkdir extra-hdrs
cp $MACSDK/usr/include/{curses.h,ncurses.h,ncurses_dll.h,unctrl.h,libintl.h,termcap.h} extra-hdrs

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
    # This is the one package that should have it
    #sudo rm $packDir/usr/local/share/info/dir
fi

sudo chown -R root:wheel "$packDir"
dpkg-deb --build -Zlzma "$packDir"

mv ${packDir}.deb $ROOT/debs

rm $ROOT/$name/${name}.${ext}
#sudo rm -r $packDir
sudo rm -r $sourceDir
rm -r $armv7dir $armv7sdir $arm64dir
