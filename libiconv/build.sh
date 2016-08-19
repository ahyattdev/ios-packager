#!/bin/bash

name=libiconv
sourceVersion=1.14
packageVersion=1.14-1
ext=tar.gz
sourceDir=$ROOT/$name/${name}-${sourceVersion}
echo $sourceDir
url=http://ftp.gnu.org/pub/gnu/$name/$name-$sourceVersion.$ext
packDir=$ROOT/$name/${name}_${packageVersion}_iphoneos-arm

armv7dir=$ROOT/$name/armv7
armv7sdir=$ROOT/$name/armv7s
arm64dir=$ROOT/$name/arm64

curl $url -o ${name}.${ext}

tar xf ${name}.${ext}

cd $sourceDir

# Currently ships without aarch64
#./autogen.sh --skip-gnulib

mkdir extra-hdrs
cp $MACSDK/usr/include/crt_externs.h extra-hdrs

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

./configure --host arm-apple-darwin

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

prefix=usr/local
binaries="$prefix/bin/iconv $prefix/lib/libcharset.1.dylib $prefix/lib/libiconv.2.dylib $prefix/lib/libcharset.a"

for binary in $binaries
do
    lipo -create $armv7dir/$binary $armv7sdir/$binary $arm64dir/$binary -output $packDir/$binary
    ldid -S $packDir/$binary
done

if [ -f $packDir/usr/local/share/info/dir ]
then
    sudo rm $packDir/usr/local/share/info/dir
fi

# Remove the remnants! OUT OUT OUT!
find $packDir -name '*.DS_Store' -type f -delete

sudo chown -R root:wheel "$packDir"
dpkg-deb --build -Zlzma "$packDir"

mv ${packDir}.deb $ROOT/debs

rm $ROOT/$name/${name}.${ext}
sudo rm -r $packDir
sudo rm -r $sourceDir
rm -r $armv7dir $armv7sdir $arm64dir
