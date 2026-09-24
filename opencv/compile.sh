#!/usr/bin/env bash

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

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLCHAIN_PREFIX="${ROOT_DIR}/../riscv-toolchain-custom/_install/bin/riscv64-unknown-linux-gnu-"
BUILD_DIR="${ROOT_DIR}/build"
INSTALL_DIR="${ROOT_DIR}/install"

if [ ! -x "${TOOLCHAIN_PREFIX}gcc" ] || [ ! -x "${TOOLCHAIN_PREFIX}g++" ]; then
  echo "RISC-V toolchain not found at ${TOOLCHAIN_PREFIX}"
  exit 1
fi

SYSROOT="$(${TOOLCHAIN_PREFIX}gcc --print-sysroot)"

mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}"

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
  -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
  -DCMAKE_LINK_SEARCH_START_STATIC=ON \
  -DCMAKE_LINK_SEARCH_END_STATIC=ON \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=riscv64 \
  -DCMAKE_C_COMPILER="${TOOLCHAIN_PREFIX}gcc" \
  -DCMAKE_CXX_COMPILER="${TOOLCHAIN_PREFIX}g++" \
  -DCMAKE_SYSROOT="${SYSROOT}" \
  -DCMAKE_FIND_ROOT_PATH="${SYSROOT}" \
  -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
  -DCMAKE_C_FLAGS="-march=rv64gc -mabi=lp64d" \
  -DCMAKE_CXX_FLAGS="-march=rv64gc -mabi=lp64d" \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_LIST=core,imgproc,imgcodecs,highgui \
  -DBUILD_TESTS=OFF \
  -DBUILD_PERF_TESTS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_opencv_apps=OFF \
  -DBUILD_JAVA=OFF \
  -DBUILD_opencv_python=OFF \
  -DBUILD_opencv_python2=OFF \
  -DBUILD_opencv_python3=OFF \
  -DWITH_IPP=OFF \
  -DWITH_OPENCL=OFF \
  -DWITH_TBB=OFF \
  -DWITH_OPENMP=OFF \
  -DWITH_GTK=OFF \
  -DWITH_QT=OFF \
  -DWITH_FFMPEG=OFF \
  -DWITH_GSTREAMER=OFF

cmake --build "${BUILD_DIR}" -j"$(nproc)"
cmake --install "${BUILD_DIR}"

echo "OpenCV build complete."
echo "Install prefix: ${INSTALL_DIR}"
echo "OpenCV config: ${INSTALL_DIR}/lib/cmake/opencv4/OpenCVConfig.cmake"
