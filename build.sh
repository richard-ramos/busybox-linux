#!/bin/bash

KERNEL_VERSION=5.15.86
BUSYBOX_VERSION=1.35.0

sudo apt-get install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf llvm

mkdir -p src
cd src
  # Kernel
  KERNEL_MAJOR=$(echo $KERNEL_VERSION | sed 's/\([0-9]*\)[^0-9].*/\1/')
  wget https://mirrors.edge.kernel.org/pub/linux/kernel/v$KERNEL_MAJOR.x/linux-5.15.86.tar.xz
  tar -xf linux-$KERNEL_VERSION.tar.xz
  cd linux-$KERNEL_VERSION
    make defconfig
    make -j$(nproc) || exit
  cd ..

  # Busybox
  git clone https://github.com/sabotage-linux/kernel-headers
  wget https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
  tar -xf busybox-$BUSYBOX_VERSION.tar.bz2
  cd busybox-$BUSYBOX_VERSION
    make defconfig
    sed 's/^.*CONFIG_EXTRA_CFLAGS.*$/CONFIG_EXTRA_CFLAGS="-I..\/kernel-headers\/x86_64\/include"/g' -i .config
    echo "CONFIG_STATIC=y" >> .config
    make CC=musl-gcc -j$(nproc) busybox || exit
  cd ..
cd ..  

cp ./src/linux-$KERNEL_VERSION/arch/x86_64/boot/bzImage ./

# initrd
mkdir initrd
cd initrd
  mkdir -p bin dev proc sys
  cd bin
    cp ../../src/busybox-$BUSYBOX_VERSION/busybox ./
    for prog in $(./busybox --list); do
      ln -s /bin/busybox ./$prog
    done
  cd ..

  echo '#!/bin/sh' > init
  echo 'mount -t sysfs sysfs /sys' >> init
  echo 'mount -t proc proc /proc' >> init
  echo 'mount -t devtmpfs udev /dev' >> init
  echo 'sysctl -w kernel.printk="2 4 1 7"' >> init
  echo '/bin/sh' >> init
  echo 'poweroff -f' >> init

  chmod -R 777 .

  find . | cpio -o -H newc > ../initrd.img
cd ..
