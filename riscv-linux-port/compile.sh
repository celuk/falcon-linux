# This file is part of https://github.com/gdrlab/falcon-linux
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

set -e

make clean;
make mrproper;
make distclean;
make ARCH=riscv CROSS_COMPILE=$(pwd)/../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu- 64-bit.config;
make ARCH=riscv CROSS_COMPILE=$(pwd)/../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu- -j16;
$(pwd)/../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-objdump -m riscv:rv64 -d vmlinux > vmlinux.dump;
## Image = vmlinux.bin
#dd if=/dev/zero bs=1 count=4096 >> ./arch/riscv/boot/Image
python3 /home/shc/projects/cva-soc/tools/bin2hex.py ./arch/riscv/boot/Image > ./arch/riscv/boot/Image.hex;
#$(pwd)/../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-objcopy -O binary ./vmlinux vmlinux.bin
#python3 /home/shc/projects/cva-soc/tools/bin2hex.py ./vmlinux.bin > ./vmlinux.hex;
$(pwd)/../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-objcopy -O verilog ./vmlinux ./vmlinux.vmem;
