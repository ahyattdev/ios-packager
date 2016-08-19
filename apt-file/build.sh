#!/bin/bash

name=apt-file
sourceVersion=2.5.4
packageVersion=2.5.4
echo $sourceDir
url="https://anonscm.debian.org/viewvc/collab-maint/deb-maint/apt-file/trunk/apt-file?revision=25782&view=co"
packDir=$ROOT/$name/${name}_${packageVersion}_iphoneos-arm

curl $url -o ${name}

if [ -d "$packDir" ]
then
  sudo rm -r "$packDir"
fi

mkdir $packDir
mkdir -p $packDir/usr/local/bin
cp $ROOT/$name/$name $packDir/usr/local/bin
rsync -ra -exclude .DS_Store DEBIAN "$packDir"
# Remove the remnants! OUT OUT OUT!
find $packDir -name '*.DS_Store' -type f -delete

sudo chown -R root:wheel "$packDir"
sudo chmod +x $packDir/usr/local/bin/$name
dpkg-deb --build -Zlzma "$packDir"

mv ${packDir}.deb $ROOT/debs

#rm $ROOT/$name/${name}
sudo rm -r $packDir
