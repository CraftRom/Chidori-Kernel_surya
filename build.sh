#!/bin/bash
#
# Compile script for LOS kernel
# Copyright (C) 2020-2021 Adithya R & @johnmart19.
# Copyright (C) 2021 Craft Rom (melles1991).

SECONDS=0 # builtin bash timer

#Set Color
blue='\033[0;34m'
grn='\033[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
txtbld=$(tput bold)
txtrst=$(tput sgr0)  

echo -e " "
echo -e " "
echo -e "$blue░▐█▀█░▐█░▐█░▐██░▐█▀█▄▒▐█▀▀█▌▒▐█▀▀▄░▐██"
echo -e "░▐█──░▐████─░█▌░▐█▌▐█▒▐█▄▒█▌▒▐█▒▐█─░█▌"
echo -e "░▐█▄█░▐█░▐█░▐██░▐█▄█▀▒▐██▄█▌▒▐█▀▄▄░▐██$nocol"
echo -e " "

# cmdline options
clean=false
regen=false
send_tg=false

for arg in "$@"; do
	case $arg in
		-c|--clean)clean=true; shift;;
		-r|--regen)regen=true; shift;;
		-t|--telegram)send_tg=true; shift;;
		-d|--description)
			shift
			case $1 in
				-*);;
				*)
					DESC="$1"
					shift
					;;
			esac
			;;

		-n|--night*)TYPE=nightly; shift;;
		-s|--stab*)TYPE=stable; shift;;
	esac
done
case $TYPE in nightly|stable);; *)TYPE=experimental;; esac

# debug:
#echo "`date`: $clean $regen $send_tg $TYPE $DESC" >>build.sh.log

KERN_VER=$(echo "$(make kernelversion)")
BUILD_DATE=$(date '+%Y-%m-%d  %H:%M')
DEVICE="POCO X3 NFC"
KERNELNAME="Chidori-Kernel-$TYPE"
ZIPNAME="Chidori-Kernel-surya-$(date '+%Y%m%d%H%M')-$TYPE.zip"
TC_DIR="$HOME/toolchains/proton-clang"
DEFCONFIG="vendor/surya-perf_defconfig"
sed -i "51s/.*/CONFIG_LOCALVERSION=\"-${KERNELNAME}\"/g" arch/arm64/configs/$DEFCONFIG

export PATH="$TC_DIR/bin:$PATH"
export KBUILD_BUILD_USER="melles1991 • Igoryan94"
export KBUILD_BUILD_HOST=CraftRom-build

echo -e "${txtbld}Type:${txtrst} $TYPE"
echo -e "${txtbld}Config:${txtrst} $DEFCONFIG"
echo -e "${txtbld}ARCH:${txtrst} arm64"
echo -e "${txtbld}Linux:${txtrst} $KERN_VER"
echo -e "${txtbld}Username:${txtrst} $KBUILD_BUILD_USER"
echo -e "${txtbld}BuildDate:${txtrst} $BUILD_DATE"
echo -e "${txtbld}Filename::${txtrst} $ZIPNAME"
echo -e " "

if ! [ -d "$TC_DIR" ]; then
	echo -e "$grn \nProton clang not found! Cloning to $TC_DIR...\n $nocol"
	if ! git clone -q --depth=1 --single-branch https://github.com/kdrag0n/proton-clang $TC_DIR; then
		echo -e "$red \nCloning failed! Aborting...\n $nocol"
		exit 1
	fi
fi

# Clean 
if $clean; then
	if [  -d "./out/" ]; then
		echo -e " "
		rm -rf ./out/
	fi
	echo -e "$grn \nFull cleaning was successful succesfully!\n $nocol"
	sleep 2
fi

# Telegram setup
push_message() {
    curl -s -X POST \
        https://api.telegram.org/bot1472514287:AAG9kYDURtPvQLM9RXN_zv4h79CIbRCPuPw/sendMessage \
        -d chat_id="-1001452770277" \
        -d text="$1" \
        -d "parse_mode=html" \
        -d "disable_web_page_preview=true"
}

push_document() {
    curl -s -X POST \
        https://api.telegram.org/bot1472514287:AAG9kYDURtPvQLM9RXN_zv4h79CIbRCPuPw/sendDocument \
        -F chat_id="-1001452770277" \
        -F document=@"$1" \
        -F caption="$2" \
        -F "parse_mode=html" \
        -F "disable_web_page_preview=true"
}

# Export defconfig
echo -e "$blue    \nMake DefConfig\n $nocol"
mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

if $regen; then
	cp out/.config arch/arm64/configs/$DEFCONFIG
	sed -i "51s/.*/CONFIG_LOCALVERSION=\"-Chidori-Kernel\"/g" arch/arm64/configs/$DEFCONFIG
	git commit -am "defconfig: surya: Regenerate" --signoff
	echo -e "$grn \nRegened defconfig succesfully!\n $nocol"
	make mrproper
	echo -e "$grn \nCleaning was successful succesfully!\n $nocol"
	sleep 4
	exit 1
fi

# Build start
echo -e "$blue    \nStarting kernel compilation...\n $nocol"
make -j$(nproc --all) O=out ARCH=arm64 CC="ccache clang" LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz dtbo.img


kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

if [ -f "$kernel" ] && [ -f "$dtb" ] && [ -f "$dtbo" ]; then
	echo -e "$blue    \nKernel compiled succesfully! Zipping up...\n $nocol"
	if ! [ -d "AnyKernel3" ]; then
		echo -e "$grn \nAnyKernel3 not found! Cloning...\n $nocol"
		if ! git clone https://github.com/CraftRom/AnyKernel3 -b surya AnyKernel3; then
			echo -e "$grn \nCloning failed! Aborting...\n $nocol"
		fi
	fi

	cp $kernel $dtbo AnyKernel3
	cp $dtb AnyKernel3/dtb
	rm -f *zip
	cd AnyKernel3
	zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
	cd ..
	echo -e "$grn \n(i)          Completed build$nocol $red$((SECONDS / 60))$nocol $grn minute(s) and$nocol $red$((SECONDS % 60))$nocol $grn second(s) !$nocol"
	echo -e "$blue    \n             Flashable zip generated $yellow$ZIPNAME.\n $nocol"
	rm -rf out/arch/arm64/boot



	# Push kernel to telegram
	if $send_tg; then
		push_document "$ZIPNAME" "
		<b>CHIDORI KERNEL | $DEVICE</b>

		New update available!
		<b>Description:</b> <i>${DESC:-No description given...}</i>
		<b>Maintainer:</b> <code>$KBUILD_BUILD_USER</code>
		<b>Type:</b> <code>$TYPE</code>
		<b>BuildDate:</b> <code>$BUILD_DATE</code>
		<b>Filename:</b> <code>$ZIPNAME</code>
		<b>md5 checksum :</b> <code>$(md5sum "$ZIPNAME" | cut -d' ' -f1)</code>

		#surya #karna #kernel"

		echo -e "$grn \n\n(i)          Send to telegram succesfully!\n $nocol"
	fi

	# TEMP
	sed -i "51s/-experimental//" arch/arm64/configs/$DEFCONFIG
else
	echo -e "$red \nKernel Compilation failed! Fix the errors!\n $nocol"
	# Push message if build error
	push_message "<b>Failed building kernel for <code>$DEVICE</code> Please fix it...!</b>"
	exit 1
fi
