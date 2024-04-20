#!/bin/bash
sudo apt-get install flex -y

# Variables
DIR=$(readlink -f .)
PARENT_DIR=$(readlink -f ${DIR}/..)

# Set environment variables
export KBUILD_BUILD_USER="Pave1c"
export KBUILD_BUILD_HOST="Acumalaka"
export CROSS_COMPILE=$PARENT_DIR/tc/clang/bin/aarch64-linux-gnu-
export CC=$PARENT_DIR/tc/clang/bin/clang
export PLATFORM_VERSION=14
export ANDROID_MAJOR_VERSION=s
export PATH=$PARENT_DIR/tc/clang/bin:$PATH
export PATH=$PARENT_DIR/tc/build-tools/path/linux-x86:$PATH
export PATH=$PARENT_DIR/tc/gas/linux-x86:$PATH
export LLVM=1 LLVM_IAS=1
export ARCH=arm64
KERNEL_MAKE_ENV="LOCALVERSION=-MoonStone-KSU"

# Color
ON_BLUE=$(echo -e "\033[44m")    # On Blue
RED=$(echo -e "\033[1;31m")    # Red
BLUE=$(echo -e "\033[1;34m")    # Blue
GREEN=$(echo -e "\033[1;32m")    # Green
Under_Line=$(echo -e "\e[4m")    # Text Under Line
STD=$(echo -e "\033[0m")        # Text Clear

# Functions
pause(){
  read -p "${RED}$2${STD}Press ${BLUE}[Enter]${STD} key to $1..." fackEnterKey
}

clang(){
  if [ ! -d $PARENT_DIR/tc/zyc-19 ]; then
    pause 'download and extract Clang 19.0.0git-20240315'
    mkdir -p $PARENT_DIR/tc/zyc-19
    cd $PARENT_DIR/tc/zyc-19
    wget https://github.com/ZyCromerZ/Clang/releases/download/19.0.0git-20240315-release/Clang-19.0.0git-20240315.tar.gz
    tar -xf Clang-19.0.0git-20240315.tar.gz
    cd $DIR
  fi
}

gas(){
  if [ ! -d $PARENT_DIR/tc/gas/linux-x86 ]; then
    pause 'clone prebuilt binaries of GNU `as` (the assembler)'
    git clone https://android.googlesource.com/platform/prebuilts/gas/linux-x86 $PARENT_DIR/tc/gas/linux-x86
    . $DIR/build_menu
  fi
}

build_tools(){
  if [ ! -d $PARENT_DIR/tc/build-tools ]; then
    pause 'clone prebuilt binaries of build tools'
    git clone https://android.googlesource.com/platform/prebuilts/build-tools $PARENT_DIR/tc/build-tools
    . $DIR/build_menu
  fi
}

variant(){
  findconfig=""
  findconfig=($(ls arch/arm64/configs/gki_defconfig))
  declare -i i=1
  shift 2
  for e in "${findconfig[@]}"; do
    echo "$i) $(basename $e | cut -d'_' -f2)"
    i=i+1
  done
  echo ""
  read -p "Select variant: " REPLY
  i="$REPLY"
  if [[ $i -gt 0 && $i -le ${#findconfig[@]} ]]; then
    export v="${findconfig[$i-1]}"
    export VARIANT=$(basename $v | cut -d'_' -f2)
    echo ${VARIANT} selected
    pause 'continue'
  else
    pause 'return to Main menu' 'Invalid option, '
    . $DIR/build_menu
  fi
}

clean(){
  echo "${GREEN}***** Cleaning in Progress *****${STD}"
  make clean
  make mrproper
  [ -d "out" ] && rm -rf out
  echo "${GREEN}***** Cleaning Done *****${STD}"
  pause 'continue'
}

build_kernel(){
  variant
  echo "${GREEN}***** Compiling kernel *****${STD}"
  [ ! -d "out" ] && mkdir out
  make -j$(nproc) -C $(pwd) $KERNEL_MAKE_ENV gki_defconfig 2>&1 | tee log.txt
  make -j$(nproc) -C $(pwd) $KERNEL_MAKE_ENV 2>&1 | tee -a log.txt

  [ -e arch/arm64/boot/Image.gz ] && cp arch/arm64/boot/Image.gz $(pwd)/out/Image.gz
  if [ -e arch/arm64/boot/Image ]; then
    cp arch/arm64/boot/Image $(pwd)/out/Image

    echo "${GREEN}***** Ready to Roar *****${STD}"
    pause 'continue'
  else
    pause 'return to Main menu' 'Kernel STUCK in BUILD!, '
  fi
}

anykernel3(){
  if [ ! -d $PARENT_DIR/AnyKernel3 ]; then
    pause 'clone AnyKernel3 - Flashable Zip Template'
    git clone https://github.com/Djmzk/AnyKernel3_marble.git $PARENT_DIR/AnyKernel3
  fi
  variant
  if [ -e $DIR/out/Image.gz ]; then
    cd $PARENT_DIR/AnyKernel3
    git reset --hard
    cp $DIR/out/Image.gz .  # Copy Image.gz to the current directory (AnyKernel3)
    sed -i "s/ExampleKernel by osm0sis/${VARIANT}/g" anykernel.sh  # Fix sed command syntax
    zip -r9 $PARENT_DIR/${VARIANT}_kernel_`date '+%Y_%m_%d'`.zip * -x .git README.md *placeholder
    cd $DIR
     rm -rf $PARENT_DIR/AnyKernel3 
    pause 'continue'
  else
    pause 'return to Main menu' 'Build kernel first, '
  fi
}


# Run once
clang
gas
build_tools

# Show menu
show_menus(){
  clear
  echo "${ON_BLUE} B U I L D - M E N U ${STD}"
  echo "1. ${Under_Line}B${STD}uild kernel"
  echo "2. ${Under_Line}C${STD}lean"
  echo "3. Make ${Under_Line}f${STD}lashable zip"
  echo "4. E${Under_Line}x${STD}it"
}

# Read input
read_options(){
  local choice
  read -p "Enter choice [ 1 - 4] " choice
  case $choice in
    1|b|B) build_kernel ;;
    2|c|C) clean ;;
    3|f|F) anykernel3;;
    4|x|X) exit 0;;
    *) pause 'return to Main menu' 'Invalid option, '
  esac
}

# Main logic - infinite loop
while true
do
  show_menus
  read_options
done