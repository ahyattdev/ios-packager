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
cp $MACSDK/usr/include/{crt_externs.h,libintl.h,termcap.h} extra-hdrs

export CC=clang
export CXX=clang++
export ORIGCFLAGS="-isysroot $IOSSDK -I`pwd`/extra-hdrs"

export CFLAGS="$ORIGCFLAGS -arch armv7"

./configure --host arm-apple-darwin

make
make install DESTDIR=$armv7dir
make clean

export CFLAGS="$ORIGCFLAGS -arch armv7s"

./configure --host armv-apple-darwin

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
binaries="$prefix/bin/info $prefix/bin/install-info"

for binary in $binaries
do
    lipo -create $armv7dir/$binary $armv7sdir/$binary $arm64dir/$binary -output $packDir/$binary
    ldid -S $packDir/$binary
done

# Remove the remnants! OUT OUT OUT!
find $packDir -name '*.DS_Store' -type f -delete

sudo chown -R root:wheel "$packDir"
dpkg-deb --build -Zlzma "$packDir"

mv ${packDir}.deb $ROOT/debs

rm $ROOT/$name/${name}.${ext}
sudo rm -r $packDir
sudo rm -r $sourceDir
rm -r $armv7dir $armv7sdir $arm64dir
