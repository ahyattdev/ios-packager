#!/bin/bash

name=man-db
sourceVersion=2.7.5
packageVersion=2.7.5-2
ext=tar.xz
sourceDir=$ROOT/$name/${name}-${sourceVersion}
echo $sourceDir
url=http://nongnu.askapache.com/$name/$name-$sourceVersion.$ext
packDir=$ROOT/$name/${name}_${packageVersion}_iphoneos-arm

armv7dir=$ROOT/$name/armv7
armv7sdir=$ROOT/$name/armv7s
arm64dir=$ROOT/$name/arm64

curl $url -o ${name}.${ext}
echo $url
file $name.$ext
xz -d ${name}.${ext}
tar xzf $name.tar

cd $sourceDir

mkdir extra-hdrs
cp $MACSDK/usr/include/crt_externs.h extra-hdrs

export CC=clang
export CXX=clang++
export ORIGCFLAGS="-isysroot $IOSSDK -I`pwd`/extra-hdrs -Wall"

export CFLAGS="$ORIGCFLAGS -arch armv7"

./configure --host armv7-apple-darwin

make CFLAGS="$CFLAGS -Wl,-flat_namespace,-undefined,suppress"
make install DESTDIR=$armv7dir
make clean

export CFLAGS="$ORIGCFLAGS -arch armv7s"

./configure --host armv7s-apple-darwin

make CFLAGS+="$CFLAGS -Wl,-flat_namespace,-undefined,suppress"
make install DESTDIR=$armv7sdir
make clean

export CFLAGS="$ORIGCFLAGS -arch arm64"

./configure --host arm-apple-darwin

make CFLAGS+="$CFLAGS -Wl,-flat_namespace,-undefined,suppress"
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
binaries="$prefix/bin/catman $prefix/bin/lexgrog $prefix/bin/man $prefix/bin/mandb $prefix/bin/manpath $prefix/bin/whatis $prefix/lib/man-db/libman-2.7.5.dylib $prefix/lib/man-db/libmandb-2.7.5.dylib $prefix/libexec/man-db/globbing $prefix/libexec/man-db/manconv $prefix/libexec/man-db/zsoelim $prefix/sbin/accessdb"

for binary in $binaries
do
    lipo -create $armv7dir/$binary $armv7sdir/$binary $arm64dir/$binary -output $packDir/$binary
    ldid -S $packDir/$binary
done

if [ -f $packDir/usr/local/share/info/dir ]
then
    rm $packDir/usr/local/share/info/dir
fi

if [ -f $packDir/usr/local/lib/charset.alias ]
then
    rm $packDir/$prefix/lib/charset.alias
fi

# Remove the remnants! OUT OUT OUT!
find $packDir -name '*.DS_Store' -type f -delete

sudo chown -R root:wheel "$packDir"
dpkg-deb --build -Zlzma "$packDir"

mv ${packDir}.deb $ROOT/debs

rm $ROOT/$name/$name.$ext
rm $ROOT/$name/${name}.tar
sudo rm -r $packDir
sudo rm -r $sourceDir
rm -r $armv7dir $armv7sdir $arm64dir
