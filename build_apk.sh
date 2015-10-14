#! /bin/bash
# Copyright (c) 2015 vizee

set -e

# require environment
if [ -z "$GOPATH" ]; then
    echo "GOPATH not set"
    exit 1
fi

if [ -z "$ANDROID_HOME" ]; then
    echo "ANDROID_HOME not set"
    exit 1
fi

if [ -z "$GOMOBILE"           ]; then GOMOBILE="$GOPATH/pkg/gomobile"; fi
if [ -z "$GOSRCDIR"           ]; then GOSRCDIR='./...'; fi
if [ -z "$APPDIR"             ]; then APPDIR=`pwd`; fi
if [ -z "$APPNAME"            ]; then APPNAME=`basename $APPDIR`; fi
if [ -z "$BUILD_TARGET_API"   ]; then BUILD_TARGET_API=23; fi
if [ -z "$BUILD_TOOL_VERSION" ]; then BUILD_TOOL_VERSION=23.0.1; fi

BUILDDIR=$APPDIR/build
mkdir -p "$BUILDDIR"

# build go sources
cd $APPDIR
GOOS=android \
    GOARCH=arm \
    GOARM=7 \
    CC=$GOMOBILE/android-ndk-r10e/arm/bin/arm-linux-androideabi-gcc \
    CXX=$GOMOBILE/android-ndk-r10e/arm/bin/arm-linux-androideabi-g++ \
    CGO_ENABLED=1 \
    go build -p=4 -pkgdir=$GOMOBILE/pkg_android_arm -tags="" -buildmode=c-shared -o $BUILDDIR/lib/armeabi/lib$APPNAME.so $GOSRCDIR

# copy AndroidManifest.xml
cp -f $APPDIR/AndroidManifest.xml $BUILDDIR/AndroidManifest.xml

AAPTARGS=-M\ $BUILDDIR/AndroidManifest.xml

# res
if [ -d $APPDIR/res ]; then
    # copy res
    if [ -d $BUILDDIR/res ]; then rm -rf $BUILDDIR/res; fi
    cp -r $APPDIR/res $BUILDDIR/
    AAPTARGS=$AAPTARGS\ -S\ $BUILDDIR/res
fi

# generate R.java
mkdir -p $BUILDDIR/gen

$ANDROID_HOME/build-tools/$BUILD_TOOL_VERSION/aapt package -f -m -J $BUILDDIR/gen $AAPTARGS -I $ANDROID_HOME/platforms/android-$BUILD_TARGET_API/android.jar

# build java sources to classes.dex
if [ -d $BUILDDIR/bin ]; then rm -rf $BUILDDIR/bin; fi

JAVASRC=$GOPATH/src/golang.org/x/mobile/app/GoNativeActivity.java
GEN_RJAVA=$(find $BUILDDIR/gen -name R.java)
if [ -f "$GEN_RJAVA" ]; then JAVASRC=$JAVASRC\ $GEN_RJAVA; fi

mkdir -p $BUILDDIR/bin
javac -source 1.7 -target 1.7 -bootclasspath $ANDROID_HOME/platforms/android-$BUILD_TARGET_API/android.jar -d $BUILDDIR/bin $JAVASRC
$ANDROID_HOME/build-tools/$BUILD_TOOL_VERSION/dx --dex --output=$BUILDDIR/bin/classes.dex $BUILDDIR/bin/

# pack resources.ap_

# copy assets
if [ -d $APPDIR/assets ]; then
    if [ -d $BUILDDIR/assets ]; then rm -rf $BUILDDIR/assets; fi
    cp -r $APPDIR/assets $BUILDDIR/
    AAPTARGS=$AAPTARGS\ -A\ $BUILDDIR/assets
fi

$ANDROID_HOME/build-tools/$BUILD_TOOL_VERSION/aapt package -f $AAPTARGS -I $ANDROID_HOME/platforms/android-$BUILD_TARGET_API/android.jar -F $BUILDDIR/bin/resources.ap_

# DEPRECATED
# build apk
java -classpath $ANDROID_HOME/tools/lib/sdklib.jar com.android.sdklib.build.ApkBuilderMain $BUILDDIR/${APPNAME}_unsigned.apk -u -z $BUILDDIR/bin/resources.ap_ -f $BUILDDIR/bin/classes.dex -nf $BUILDDIR/lib