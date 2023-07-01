#!/bin/bash

export LOCALVERSION=-tegra
export ARCH=arm64
export CROSS_COMPILE_AARCH64_PATH=/media/canlab/DriverA/Nvidia/ORIN/l4t-gcc/bin
export CROSS_COMPILE_AARCH64=/media/canlab/DriverA/Nvidia/ORIN/l4t-gcc/bin/aarch64-buildroot-linux-gnu-
JETPACK=/media/canlab/DriverA/Nvidia/ORIN_NX/JetPack_5.1.1_Linux_JETSON_ORIN_NX_TARGETS
KERNEL_OUT=${JETPACK}/Linux_for_Tegra/source/public/kernel/kernel-5.10/build
KERNEL_MODULES_OUT=${JETPACK}/Linux_for_Tegra/rootfs/usr
KERNEL_VERSION=5.10.104-tegra
SUDO_PASSWORD='1'

cat <<EOF
************************************
*                                  *
*  Kenrel Make clean [Y/N]	   *
*                                  *
************************************
EOF

read value

if [ $value == 'y' -o $value == 'Y' ]; then
	cd $KERNEL_OUT
	if [ $? == 0 ]; then
		echo 'No build folder! Still Progress'
	else
cat <<EOF
************************************
*  Kenrel Make clean     	   *
************************************
EOF
	make clean & make mrproper
	fi
elif [ $value == 'n' -o $value == 'N' ]; then
cat <<EOF
************************************
*  Kenrel Make No clean     	   *
************************************
EOF
fi

cat <<EOF
************************************
*                                  *
*  DTB / FULL Build [1/2]          *
*                                  *
************************************
EOF

read value

if [ $value == '1' ]; then
cat <<EOF
************************************
*                                  *
*  DTB Build		           *
*                                  *
************************************
EOF
	cd ${JETPACK}/Linux_for_Tegra/source/public/kernel/kernel-5.10/
	make ARCH=arm64 O=$KERNEL_OUT CROSS_COMPILE=${CROSS_COMPILE_AARCH64} -j12
cat <<EOF
************************************
*                                  *
*  Change device tree		   *
*                                  *
************************************
EOF
	cp -r ./build/arch/arm64/boot/dts/nvidia/* $JETPACK/Linux_for_Tegra/kernel/dtb/
	exit 1
elif [ $value == '2' ]; then
cat <<EOF
************************************
*                                  *
*  FULL Build		           *
*                                  *
************************************
EOF
fi

cat <<EOF
************************************
*                                  *
*  Make build folder 		   *
*                                  *
************************************
EOF

mkdir -p $KERNEL_OUT

cat <<EOF
************************************
*                                  *
*  Kernel build 		   *
*                                  *
************************************
EOF

cd $JETPACK/Linux_for_Tegra/source/public
pwd
./nvbuild.sh -o $KERNEL_OUT

cat <<EOF
************************************
*                                  *
*  Change nvgpu.ko		   *
*                                  *
************************************
EOF

cd $KERNEL_OUT
echo $SUDO_PASSWORD | sudo -S cp -r drivers/gpu/nvgpu/nvgpu.ko $JETPACK/Linux_for_Tegra/rootfs/usr/lib/modules/$KERNEL_VERSION/kernel/drivers/gpu/nvgpu/

cat <<EOF
************************************
*                                  *
*  Change device tree		   *
*                                  *
************************************
EOF

cp -r arch/arm64/boot/dts/nvidia/* $JETPACK/Linux_for_Tegra/kernel/dtb/

cat <<EOF
************************************
*                                  *
*  Change Image		           *
*                                  *
************************************
EOF

cp -r arch/arm64/boot/Image $JETPACK/Linux_for_Tegra/kernel/Image

cat <<EOF
************************************
*                                  *
*  Install modules in temporal location	           *
*                                  *
************************************
EOF

echo $SUDO_PASSWORD | sudo -S make modules_install ARCH=arm64 O=$KERNEL_OUT CROSS_COMPILE=${CROSS_COMPILE_AARCH64} INSTALL_MOD_PATH=$KERNEL_MODULES_OUT INSTALL_MOD_STRIP=1

cat <<EOF
************************************
*                                  *
*  Regenerate kernel modules supplement file           *
*                                  *
************************************
EOF

cd $KERNEL_MODULES_OUT
tar --owner root --group root -cjf ${JETPACK}/Linux_for_Tegra/kernel/kernel_supplements.tbz2 lib/modules

