#!/bin/bash

export KBUILD_BUILD_USER="Unicote"
export KBUILD_BUILD_HOST="M533IA"
export KBUILD_BUILD_VERSION="10"
export LOCALVERSION=""
export KBUILD_COMPILER_STRING="$(../clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

export PATH="$COMPILER_DIR/bin:$PATH"

export COMPILER_DIR="../clang"
KERNEL_DEFCONFIG="surya_defconfig"

mkdir -p out
make O=out ARCH=arm64 $KERNEL_DEFCONFIG

echo "Starting compilation..."
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip \

if [ -f "out/arch/arm64/boot/Image.gz" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo "Kernel compiled succesfully!"
else
echo -e "\nCompilation failed!"
fi

kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

rm ../AnyKernel3/Image.gz
rm -rf ../AnyKernel3/dtb/sdmmagpie.dtb
rm ../AnyKernel3/dtbo.img

cp $kernel $dtbo ../AnyKernel3
cp $dtb ../AnyKernel3/dtb

#rm -rf out/arch/arm64/boot
cd ../AnyKernel3
zip -r9 "kernel" * -x .git README.md
