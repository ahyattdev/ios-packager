set -e

NAME=gnupg
DISPLAY_NAME="GNU Privacy Guard"
SOURCE_VERSION=2.1.17
PACKAGE_VERSION=2.1.17
EXT=.tar.bz2
ARCHIVE_NAME=$NAME-${SOURCE_VERSION}$EXT
SOURCE_DIR=$NAME-$SOURCE_VERSION
PACKAGE_DIR=${NAME}_${PACKAGE_VERSION}_$ARCHITECTURE
URL=https://gnupg.org/ftp/gcrypt/$NAME/$ARCHIVE_NAME

if ! [ -f $ARCHIVE_NAME ]
then
    curl "$URL" -o $ARCHIVE_NAME
fi

if ! [ -d "$SOURCE_DIR" ]
then
    tar xf $ARCHIVE_NAME
fi

if ! [ -f "$DEB_DIR/$PACKAGE_DIR.deb" ]
then
    sudo rm -rf "`pwd`/$PACKAGE_DIR"
    if [ -f controlstub ]
    then
        rm controlstub
    fi

    pushd $SOURCE_DIR

    ./configure CFLAGS="$ARCHS -isysroot $SDK -Wl,-flat_namespace,-undefined,suppress" --host arm-apple-darwin --prefix=/usr
    make -j$JOBS
    make install DESTDIR="`pwd`/../$PACKAGE_DIR"

    popd

    recursive_ldid "$PACKAGE_DIR"

    cp -r DEBIAN "$PACKAGE_DIR/DEBIAN"

    echo "Package: $NAME" >> controlstub
    echo "Name: $DISPLAY_NAME" >> controlstub
    echo "Version: $PACKAGE_VERSION" >> controlstub
    echo "Architecture: $ARCHITECTURE" >> controlstub
    echo "Maintainer: $MAINTAINER" >> controlstub

    cat controlstub DEBIAN/control > "$PACKAGE_DIR/DEBIAN/control"

    find "$PACKAGE_DIR" -name .DS_Store -delete
    if [ -f "$PACKAGE_DIR/usr/share/info/dir" ]
    then
        rm "$PACKAGE_DIR/usr/share/info/dir"
    fi
    if [ -f "$PACKAGE_DIR/usr/local/share/info/dir" ]
    then
        rm "$PACKAGE_DIR/usr/local/share/info/dir"
    fi

    sudo chown -R root:wheel "$PACKAGE_DIR"
    dpkg-deb --build -Zlzma "$PACKAGE_DIR"
    cp "$PACKAGE_DIR.deb" "$DEB_DIR"
fi
