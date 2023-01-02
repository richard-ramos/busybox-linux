#!/bin/bash

KERNEL_VERSION=5.15.86
BUSYBOX_VERSION=1.35.0

qemu-system-x86_64 -kernel bzImage -initrd initrd.img
