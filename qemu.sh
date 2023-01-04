#!/bin/bash

qemu-system-x86_64 -kernel bzImage -initrd initramfs.cpio -nographic -append "init=/bin/sh console=ttyS0"
