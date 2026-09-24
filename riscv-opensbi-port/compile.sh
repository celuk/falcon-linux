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

make distclean;
dtc -I dts -O dtb -o ./platform/template/custom.dtb ./platform/template/custom.dts;
python3 /home/shc/projects/cva-soc/tools/bin2hex.py ./platform/template/custom.dtb > ./platform/template/custom.dtb.hex;
../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-objcopy -I binary -O verilog ./platform/template/custom.dtb ./platform/template/custom.dtb.vmem;
make ARCH=riscv PLATFORM_RISCV_XLEN=64 CROSS_COMPILE=../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu- PLATFORM_RISCV_ISA=rv64imafdc PLATFORM=template FW_DYNAMIC=y FW_TEXT_START=0x80000000
python3 /home/shc/projects/cva-soc/tools/bin2hex.py ./build/platform/template/firmware/fw_dynamic.bin > ./build/platform/template/firmware/fw_dynamic.hex;
../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-objdump -m riscv:rv64 -d -M numeric,no-aliases ./build/platform/template/firmware/fw_dynamic.elf > ./build/platform/template/firmware/fw_dynamic.dump;
../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-objcopy -O verilog ./build/platform/template/firmware/fw_dynamic.elf ./build/platform/template/firmware/fw_dynamic.vmem;
python3 /home/shc/projects/cva-soc/tools/vmem_to_ddr3_init.py -i ./build/platform/template/firmware/fw_dynamic.vmem -i2 /home/shc/projects/clones/riscv-linux-ue/vmlinux.vmem -i3 ./platform/template/custom.dtb.vmem -o ./build/platform/template/firmware/fw_dynamic_mem_init.txt;
