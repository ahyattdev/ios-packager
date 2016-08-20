#!/usr/local/bin/bash

name=groff
sourceVersion=1.22.3
packageVersion=1.22.3-1
ext=tar.gz
sourceDir=$ROOT/$name/${name}-${sourceVersion}
echo $sourceDir
url=http://ftp.gnu.org/gnu/$name/$name-$sourceVersion.$ext
packDirName=${name}_${packageVersion}_iphoneos-arm
packDir=$ROOT/$name/$packDirName

armv7dir=$ROOT/$name/armv7
armv7sdir=$ROOT/$name/armv7s
arm64dir=$ROOT/$name/arm64

curl $url -o ${name}.${ext}
echo $url
tar xzf $name.$ext

cd $sourceDir

mkdir extra-hdrs
cp -f $MACSDK/usr/include/crt_externs.h extra-hdrs

build() {
    arch=$1
    dest=$2
    flags="-arch $arch -isysroot $IOSSDK -I`pwd`/extra-hdrs -Wall"
    ./configure --host arm-apple-darwin CC=clang CXX=clang++ CFLAGS="$flags" LDFLAGS="$flags" CXXFLAGS="$flags"
    make GROFF_BIN_PATH=/usr/local/Cellar/groff/1.22.3/bin GROFFBIN=/usr/local/Cellar/groff/1.22.3/bin/groff TROFFBIN=/usr/local/Cellar/groff/1.22.3/bin/troff LC_ALL=C CC=clang CXX=clang++ CFLAGS="$flags" LDFLAGS="$flags" CXXFLAGS="$flags"
    make install DESTDIR=$dest
    make clean
}

build armv7 $armv7dir
build armv7s $armv7sdir
build arm64 $arm64dir

cd $ROOT/$name

if [ -d "$packDir" ]
then
  sudo rm -r "$packDir"
fi

rsync -ra --exclude .DS_Store $armv7dir/* "$packDir"
rsync -ra -exclude .DS_Store DEBIAN "$packDir"

cd $packDir

shopt -s globstar
for file in **
do
    lipo -create $armv7dir/$file $armv7sdir/$file $arm64dir/$file -output $packDir/$file
    ldid -S $packDir/$file
done

cd $ROOT/$name

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
