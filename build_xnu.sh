#!/bin/bash
# This script is based on zhouwei's build-xnu-6153.141.1.sh.
# For further information, refer to https://gist.github.com/zhuowei/69c886423642cd77fd2c010f4d54b1c4

if ! [[ $OSTYPE == 'darwin'* ]]; then
  echo 'This command can only be ran on a macOS host. Sorry!'
  exit 1
fi

# Set a permissive umask just in case.
umask 022

# Print commands and exit on failure.
set -ex

export DEVELOPER_DIR="/Applications/Xcode_15.0.app/Contents/Developer"
export SDKPATH="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX14.0.sdk"
export TOOLCHAINPATH="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain"
[ -d "${SDKPATH}" ] && [ -d "${TOOLCHAINPATH}" ]

# Install CTF tools from dtrace
cd dtrace
xcodebuild install -sdk macosx -target ctfconvert -target ctfdump -target ctfmerge ARCHS='x86_64' VALID_ARCHS='x86_64' SRCROOT="${PWD}" OBJROOT="${PWD}/obj" SYMROOT="${PWD}/sym" DSTROOT="${PWD}/dst"
sudo ditto "${PWD}/dst/${TOOLCHAINPATH}" "${TOOLCHAINPATH}"
cd ..

# Install AvailabilityVersions. This writes to ${SDKPATH}/usr/local/libexec.
cd AvailabilityVersions
mkdir -p dst
make install
sudo ditto "${PWD}/dst/usr/local" "${SDKPATH}/usr/local"
cd ..

# Install the XNU headers needed by libdispatch.
cd xnu
make SDKROOT=macosx ARCH_CONFIGS="X86_64" installhdrs
sudo ditto "$PWD/BUILD/dst" "${SDKPATH}"
cd ..

# Build and install libdispatch's libfirehose target to
# ${SDKPATH}/usr/local.
cd libdispatch
xcodebuild install -sdk macosx ARCHS='x86_64' VALID_ARCHS='x86_64' -target libfirehose_kernel PRODUCT_NAME=firehose_kernel DSTROOT=$PWD/dst
sudo ditto "$PWD/dst/usr/local" "${SDKPATH}/usr/local"
cd ..

echo "attempting to build a DEVELOPMENT kernel with all local variables and arguments"
cd xnu
export CFLAGS_DEVELOPMENTX86_64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2"
export CXXFLAGS_DEVELOPMENTX86_64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2"

make BUILD_LTO=0 ARCH_CONFIGS="X86_64" \
KERNEL_CONFIGS=DEVELOPMENT \
SDK_ROOT=macosx -j8

echo $(ls -a)