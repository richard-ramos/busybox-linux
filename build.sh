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

# initramfs
rm -rf ./initramfs*
mkdir initramfs
cd initramfs
  install -d ./{bin,dev,etc/rc.d,etc/init.d/{udhcpd,syslogd,klogd},usr/share/udhcpc}
  install -d -m0555 ./{sys,proc}

  cd bin
    cp ../../src/busybox-$BUSYBOX_VERSION/busybox ./
    for prog in $(./busybox --list); do
      ln -s /bin/busybox ./$prog
    done
  cd ..

  ln -s /bin/busybox ./init

  # TODO: create directory structure
  install -m0755 ../files/rcS ./etc/init.d/
  install -m0755 ../files/inittab ./etc/
  install -m0755 ../files/simple.script ./usr/share/udhcpc/default.script
  install -m0755 ../files/resolv.conf ./etc/.
  install -m0755 ../files/hostname ./etc/.
  install -m0755 ../files/udhcpc.run ./etc/init.d/udhcpd/run
  install -m0755 ../files/syslog.run ./etc/init.d/syslogd/run
  install -m0755 ../files/klogd.run ./etc/init.d/klogd/run

  ln -s /etc/init.d/syslogd ./etc/rc.d
  ln -s /etc/init.d/klogd ./etc/rc.d
  ln -s /etc/init.d/udhcpd ./etc/rc.d

  find . -print0 | cpio --null -ov --format=newc  > ../initramfs.cpio
cd ..
