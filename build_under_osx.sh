if ! [[ $OSTYPE == 'darwin'* ]]; then
  echo 'This command can only be ran on a macOS host. Sorry!'
  exit 1
fi

echo "attempting to build a DEVELOPMENT kernel with all local variables and arguments"
SDK_LIST = $(xcodebuild -showsdks)
echo "xcode reports the following available SDKs"
echo "$SDK_LIST"
OSX_SDK = $(xcrun --sdk macosx14.0 --show-sdk-path)
echo "using macOS SDK at $OSX_SDK"

cd xnu
export CFLAGS_DEVELOPMENTARM64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2"
export CXXFLAGS_DEVELOPMENTARM64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2"

make \
ARCH_CONFIGS="X86_64" \
KERNEL_CONFIGS=DEVELOPMENT \
SDK_ROOT="$OSX_SDK"\
-j8

echo $(ls -a)