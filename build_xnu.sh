#!/bin/bash
# This script is based on zhouwei's build-xnu-6153.141.1.sh.
# For further information, refer to https://gist.github.com/zhuowei/69c886423642cd77fd2c010f4d54b1c4

export DEVELOPER_DIR="/Applications/Xcode_14.3.1.app/Contents/Developer"

if ! [[ $OSTYPE == 'darwin'* ]]; then
  echo 'This command can only be ran on a macOS host. Sorry!'
  exit 1
fi

# Set a permissive umask just in case.
umask 022

# Print commands and exit on failure.
set -ex

# Get the SDK path.
SDKPATH="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.3.sdk"
[ -d "${SDKPATH}" ]

# Install AvailabilityVersions. This writes to ${SDKPATH}/usr/local/libexec.
cd AvailabilityVersions
mkdir -p dst
make install SRCROOT="${PWD}" DSTROOT="${PWD}/dst"
sudo ditto "${PWD}/dst/usr/local" "${SDKPATH}/usr/local"
cd ..

# Install the XNU headers we'll need for libdispatch. This OVERWRITES files in the specified MacOSX SDK.
cd xnu
mkdir -p BUILD.hdrs/obj BUILD.hdrs/sym BUILD.hdrs/dst
make installhdrs SDKROOT=macosx ARCH_CONFIGS=X86_64 SRCROOT="${PWD}" OBJROOT="${PWD}/BUILD.hdrs/obj" SYMROOT="${PWD}/BUILD.hdrs/sym" DSTROOT="${PWD}/BUILD.hdrs/dst" HOST_OS_VERSION="13.4"
xcodebuild installhdrs -project libsyscall/Libsyscall.xcodeproj -sdk macosx ARCHS="x86_64" SRCROOT="${PWD}/libsyscall" OBJROOT="${PWD}/BUILD.hdrs/obj" SYMROOT="${PWD}/BUILD.hdrs/sym" DSTROOT="${PWD}/BUILD.hdrs/dst"
# Set permissions correctly before dittoing over the SDK.
sudo chown -R root:wheel BUILD.hdrs/dst/
sudo ditto BUILD.hdrs/dst "${SDKPATH}"
cd ..

# Install libplatform headers to ${SDKPATH}/usr/local/include.
cd libplatform
sudo ditto "${PWD}/include" "${SDKPATH}/usr/local/include"
sudo ditto "${PWD}/private"  "${SDKPATH}/usr/local/include"
cd ..

# Build and install libdispatch's libfirehose_kernel target to
# ${SDKPATH}/usr/local.
cd libdispatch
mkdir -p obj sym dst
xcodebuild install -project libdispatch.xcodeproj -target libfirehose_kernel -sdk macosx ARCHS="x86_64" SRCROOT="${PWD}" OBJROOT="${PWD}/obj" SYMROOT="${PWD}/sym" DSTROOT="${PWD}/dst"
sudo ditto "${PWD}/dst/usr/local" "${SDKPATH}/usr/local"
cd ..

echo "attempting to build a DEVELOPMENT kernel with all local variables and arguments"


cd xnu
export CFLAGS_DEVELOPMENTARM64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2"
export CXXFLAGS_DEVELOPMENTARM64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2"

make \
ARCH_CONFIGS="X86_64" \
KERNEL_CONFIGS=DEVELOPMENT \
SDK_ROOT=macosx \
-j8

echo $(ls -a)