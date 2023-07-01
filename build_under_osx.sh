if ! [[ $OSTYPE == 'darwin'* ]]; then
  echo 'This command can only be ran on a macOS host. Sorry!'
  exit 1
fi

echo "attempting to build a DEVELOPMENT kernel with all local variables and arguments"

cd xnu && CFLAGS_DEVELOPMENTARM64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2" CXXFLAGS_DEVELOPMENTARM64="-O0 -g -DKERNEL_STACK_MULTIPLIER=2" make \
ARCH_CONFIGS="X86_64" \
KERNEL_CONFIGS=DEVELOPMENT \
SDK_ROOT=macosx14.0 \
-j8

echo $(cd xnu && ls -a)