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

SHELL := /bin/bash
.PHONY: all opensbi lrzsz opencv tengine nvdla busybox linux toolchain

all: opensbi lrzsz busybox linux nvdla busybox linux

opensbi:
	pushd riscv-opensbi-port && ./compile.sh && popd

busybox:
	pushd riscv-busybox-port && ./compile.sh && popd

linux:
	pushd riscv-linux-port && ./compile.sh && popd

lrzsz:
	pushd lrzsz && ./compile.sh && popd

nvdla:
	pushd nvdla/sw && ./compile.sh && popd

opencv:
	pushd opencv && ./compile.sh && popd

tengine:
	pushd tengine && ./compile.sh && popd

toolchain:
	pushd riscv-toolchain-custom && ./compile.sh && popd
