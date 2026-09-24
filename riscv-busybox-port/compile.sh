#!/bin/bash

# This file is part of https://github.com/celuk/falcon-linux
# Copyright (C) 2026  Seyyid Hikmet Celik
#                     seyyid4091@gmail.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

sudo rm -rf ./_install ./rootfs.cpio.gz;
make distclean;
make defconfig;
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config;
export CROSS_COMPILE=../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-;
make -j14;
make install;

# Copy lrzsz binaries if they exist
if [ -f "../lrzsz/rz" ] && [ -f "../lrzsz/sz" ]; then
    echo "Copying lrzsz binaries..."
    cp ../lrzsz/rz ./_install/bin/rz
    cp ../lrzsz/sz ./_install/bin/sz
    chmod +x ./_install/bin/rz ./_install/bin/sz
    echo "Stripping lrzsz binaries..."
    "${CROSS_COMPILE}strip" ./_install/bin/rz ./_install/bin/sz
else
    echo "Warning: lrzsz binaries not found at ../lrzsz/"
fi

# Copy opendla.ko
if [ -f "../nvdla/sw/kmd/port/linux/opendla.ko" ]; then
    echo "Copying opendla.ko..."
    cp "../nvdla/sw/kmd/port/linux/opendla.ko" ./_install/opendla.ko
    echo "Stripping opendla.ko..."
    "${CROSS_COMPILE}strip" --strip-debug ./_install/opendla.ko
else
    echo "Warning: opendla.ko not found at ../nvdla/sw/kmd/port/linux/"
fi

# Copy nvdla_runtime
if [ -f "../nvdla/sw/umd/out/apps/runtime/nvdla_runtime/nvdla_runtime" ]; then
    echo "Copying nvdla_runtime..."
    cp "../nvdla/sw/umd/out/apps/runtime/nvdla_runtime/nvdla_runtime" ./_install/bin/nvdla_runtime
    chmod +x ./_install/bin/nvdla_runtime
    echo "Stripping nvdla_runtime..."
    "${CROSS_COMPILE}strip" ./_install/bin/nvdla_runtime
else
    echo "Warning: nvdla_runtime not found at ../nvdla/sw/umd/out/apps/runtime/nvdla_runtime/nvdla_runtime"
fi

## Copy Tengine OpenDLA example binaries
#if [ -f "../tengine/build-riscv/examples/tm_classification_opendla" ]; then
#    echo "Copying tm_classification_opendla..."
#    cp "../tengine/build-riscv/examples/tm_classification_opendla" ./_install/bin/tm_classification_opendla
#    chmod +x ./_install/bin/tm_classification_opendla
#    echo "Stripping tm_classification_opendla..."
#    "${CROSS_COMPILE}strip" ./_install/bin/tm_classification_opendla
#else
#    echo "Warning: tm_classification_opendla not found at ../tengine/build-riscv/examples/"
#fi
#
#if [ -f "../tengine/build-riscv/examples/tm_yolox_opendla" ]; then
#    echo "Copying tm_yolox_opendla..."
#    cp "../tengine/build-riscv/examples/tm_yolox_opendla" ./_install/bin/tm_yolox_opendla
#    chmod +x ./_install/bin/tm_yolox_opendla
#    echo "Stripping tm_yolox_opendla..."
#    "${CROSS_COMPILE}strip" ./_install/bin/tm_yolox_opendla
#else
#    echo "Warning: tm_yolox_opendla not found at ../tengine/build-riscv/examples/"
#fi
#
#if [ -f "../tengine/build-riscv/examples/tm_yolov3_tiny_opendla" ]; then
#    echo "Copying tm_yolov3_tiny_opendla..."
#    cp "../tengine/build-riscv/examples/tm_yolov3_tiny_opendla" ./_install/bin/tm_yolov3_tiny_opendla
#    chmod +x ./_install/bin/tm_yolov3_tiny_opendla
#    echo "Stripping tm_yolov3_tiny_opendla..."
#    "${CROSS_COMPILE}strip" ./_install/bin/tm_yolov3_tiny_opendla
#else
#    echo "Warning: tm_yolov3_tiny_opendla not found at ../tengine/build-riscv/examples/"
#fi

#cp "../tengine/models/resnet18-cifar10-nosoftmax-relu_int8.tmfile" ./_install/;
#cp "../tengine/models/yolox_nano_relu_int8.tmfile" ./_install/;
#cp "../tengine/images/person.jpg" ./_install/;
#cp "../tengine/images/cat.jpg" ./_install/;
#cp "../tengine/images/dog.jpg" ./_install/;

cp "../nvdla/loadables/lenet/lenet-fast-math.nvdla" ./_install;
cp "../nvdla/loadables/resnet18-cifar10/cifar-default.nvdla" ./_install;
cp "../nvdla/loadables/resnet18-imagenet2012/imagenet-default.nvdla" ./_install;

cp "../nvdla/loadables/lenet/images/0_8.jpg" ./_install;
cp "../nvdla/loadables/resnet18-cifar10/images/cat_32.jpg" ./_install;
cp "../nvdla/loadables/resnet18-imagenet2012/images/331_hare.jpg" ./_install;
#cp "../nvdla/loadables/resnet18-imagenet2012/images/742_printer.jpg" ./_install;

cp "./logo.txt" ./_install;

cd _install;
mkdir -p dev proc sys etc/init.d;
sudo rm -rf dev/console dev/null;
sudo mknod dev/console c 5 1;
sudo mknod dev/null c 1 3;
#sudo mknod dev/ttyS0 c 4 64;

echo '#!/bin/sh' > ./etc/init.d/rcS
echo 'mount -t devtmpfs devtmpfs /dev' >> ./etc/init.d/rcS
echo 'mount -t proc none /proc' >> ./etc/init.d/rcS
echo 'mount -t sysfs none /sys' >> ./etc/init.d/rcS
echo 'echo "Loading OpenDLA kernel module..."' >> ./etc/init.d/rcS
echo 'insmod ./opendla.ko' >> ./etc/init.d/rcS
echo 'cat logo.txt' >> ./etc/init.d/rcS
echo 'echo "Starting shell..."' >> ./etc/init.d/rcS
#echo 'ls -al' >> ./etc/init.d/rcS
#echo 'exec /bin/sh' >> ./etc/init.d/rcS

echo 'nvdla_runtime --image 0_8.jpg --loadable lenet-fast-math.nvdla --rawdump' >> ./etc/init.d/rcS
echo 'nvdla_runtime --image cat_32.jpg --loadable cifar-default.nvdla --rawdump' >> ./etc/init.d/rcS
echo 'nvdla_runtime --image 331_hare.jpg --loadable imagenet-default.nvdla --rawdump' >> ./etc/init.d/rcS
#echo 'nvdla_runtime --image 742_printer.jpg --loadable imagenet-default.nvdla --rawdump' >> ./etc/init.d/rcS

echo 'exec setsid cttyhack /bin/sh' >> ./etc/init.d/rcS

chmod +x ./etc/init.d/rcS;
ln -s ./etc/init.d/rcS ./init;
# find . | cpio -H newc -o --owner root:root | gzip > ../rootfs.cpio.gz;
find . | cpio -H newc -o --owner root:root > ../rootfs.cpio;
