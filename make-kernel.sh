#! /bin/bash

# Copyright (C) 2021-2022 rk134
# Thanks to eun0115, starlight5234 and ghostmaster69-dev
export DEVICE="VINCE"
export CONFIG="vince-perf_defconfig"
export CHANNEL_ID="-1001750098178"
export TELEGRAM_TOKEN=$BOT_API_KEY
export TC_PATH="$HOME/toolchains"
PATH="${PWD}/clang/bin:$PATH"
export ZIP_DIR="$(pwd)/Flasher"
export KERNEL_DIR=$(pwd)
export AZURE_COMPILE="yes"
export KBUILD_BUILD_HOST="Elemental-Local"
export KBUILD_BUILD_USER="rk134"

# FUNCTIONS

# Upload buildlog to group
tg_erlog()
{
	ERLOG=$HOME/build/build${BUILD}.txt
	curl -F document=@"$ERLOG"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
			-F chat_id=$CHANNEL_ID \
			-F caption="Build ran into errors after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds, plox check logs"
}

# Upload zip to channel
tg_pushzip() 
{
	FZIP=$ZIP_DIR/$ZIP
	curl -F document=@"$FZIP"  "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
			-F chat_id=$CHANNEL_ID \
			-F caption="Build Finished after $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds"
}

# Send Updates
function tg_sendinfo() {
	curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
		-d "parse_mode=html" \
		-d text="${1}" \
		-d chat_id="${CHANNEL_ID}" \
		-d "disable_web_page_preview=true"
}

# Clone the toolchains and export required information
function clone_tc() {
[ -d ${TC_PATH} ] || mkdir ${TC_PATH}

if [ "$AZURE_COMPILE" == "no" ]; then
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git ${TC_PATH}/clang
	export PATH="${TC_PATH}/clang/bin:$PATH"
	export STRIP="${TC_PATH}/clang/aarch64-linux-gnu/bin/strip"
	export COMPILER="Clang 14.0.0"
else
    git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang clang
    git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 los-4.9-64
    git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 los-4.9-32
    export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
fi
}

# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
        -d chat_id="$CHANNEL_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>Test Kernel</b>%0ABuild started on <code>Elemental-Local</code>%0AFor device <b>Redmi 5 Plus</b> (vince)%0AOn branch: <code>$(git rev-parse --abbrev-ref HEAD)</code></n>%0AUnder commit: <code>$(git log --pretty=format:'"%h : %s"' -1)</code></n>%0AUsing compiler: <code>${KBUILD_COMPILER_STRING}</code></n>%0AStarted on <code>$(date)</code></n>%0A<b>Build Status:</b> "$TYPE""
}

# Send a sticker
function start_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
        -d sticker="CAACAgQAAxkBAAEDIYdhctPrAm1Ydl3sFori9vNNnjAoigAC9AkAAl79YVHW7zfYKT9-XyEE" \
        -d chat_id=$CHANNEL_ID
}

function error_sticker() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
        -d sticker="$STICKER" \
        -d chat_id=$CHANNEL_ID
}

# Compile this gay-ass kernel
function compile() {

    make O=out ARCH=arm64 vince-perf_defconfig
    make -j$(nproc --all) O=out \
                          ARCH=arm64 \
			  CC=clang \
			  CROSS_COMPILE=aarch64-linux-gnu- \
			  CROSS_COMPILE_ARM32=arm-linux-gnueabi-

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
}

# Zip this gay-ass kernel
function make_flashable() {
    
cd $ZIP_DIR
make clean &>/dev/null
cp $KERN_IMG $ZIP_DIR/zImage
if [ "$TYPE" == "stable" ]; then
    make stable &>/dev/null
elif [ "$TYPE" == "beta" ]; then
    make beta &>/dev/null
else
    make test &>/dev/null
fi
ZIP=$(echo *.zip)
tg_pushzip

}

# Credits: @madeofgreat
BTXT="$HOME/build/buildno.txt" #BTXT is Build number TeXT
if ! [ -a "$BTXT" ]; then
	mkdir $HOME/build
	touch $HOME/build/buildno.txt
	echo $RANDOM > $BTXT
fi

BUILD=$(cat $BTXT)
BUILD=$(($BUILD + 1))
echo ${BUILD} > $BTXT

# Sticker selection
stick=$(($RANDOM % 5))

if [ "$stick" == "0" ]; then
	STICKER="CAACAgIAAxkBAAEDIWhhcssHSMR1HTAHtKOby21tVafvWgAC_gADVp29CtoEYTAu-df_IQQ"
elif [ "$stick" == "1" ];then
	STICKER="CAACAgIAAxkBAAEDIXlhcsvK31evc58huNXRZnSWf62R2AAC_w4AAhSUAAFL2_NFL9rIYIAhBA"
elif [ "$stick" == "2" ];then
	STICKER="CAACAgUAAxkBAAEDIXthcsvYV4zwNP0ousx1ULwkKGRdygACIAADYOojP1RURqxGbEhrIQQ"
elif [ "$stick" == "3" ];then
	STICKER="CAACAgUAAxkBAAEDIX1hcsvr8e6DUr1J4KmHCtI98gx1xwACNgADP9jqMxV1oXRlrlnXIQQ"
elif [ "$stick" == "4" ];then
	STICKER="CAACAgEAAxkBAAEDIYFhcswQNqw8ZPubg7zGQkNhaYGTBAACKwIAAvx0QESn-U6NZyYYfSEE"
fi

#-----------------------------------------------------------------------------------------------------------#
clone_tc
make mrproper && rm -rf out
start_sticker
sendinfo
compile
if ! [ -a "$KERN_IMG" ]; then
	tg_erlog && error_sticker
	exit 1
else
	make_flashable
fi