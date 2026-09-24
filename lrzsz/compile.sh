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

autoconf
CC=../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-gcc CXX=../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-g++ LDFLAGS="-static" ./configure --host=riscv64
make LDFLAGS="-all-static"
cp src/lsz .
cp src/lrz .
cp lrz rz
cp lsz sz
