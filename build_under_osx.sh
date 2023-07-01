if ! [[ $OSTYPE == 'darwin'* ]]; then
  echo 'This command can only be ran on a macOS host. Sorry!'
  exit 1
fi

echo "attempting to build a DEVELOPMENT kernel with all local variables and arguments"

OSX_SDK = "/Applications/Xcode_15.0.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX14.0.sdk"
echo "using hardcoded macOS SDK at $OSX_SDK"

cd xnu
export CFLAGS_DEVELOPMENTARM64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2"
export CXXFLAGS_DEVELOPMENTARM64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2"

make \
ARCH_CONFIGS="X86_64" \
KERNEL_CONFIGS=DEVELOPMENT \
SDK_ROOT="$OSX_SDK"\
-j8

echo $(ls -a)