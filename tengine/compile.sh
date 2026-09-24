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
BUILD_DIR="${ROOT_DIR}/build-riscv"
NVDLA_SW_DIR="${ROOT_DIR}/../nvdla/sw"
NVDLA_RUNTIME_LIB="${NVDLA_SW_DIR}/umd/out/core/src/runtime/libnvdla_runtime/libnvdla_runtime.a"
NVDLA_COMPILER_LIB="${NVDLA_SW_DIR}/umd/out/core/src/compiler/libnvdla_compiler/libnvdla_compiler.a"
OPENCV_INSTALL_DIR="${ROOT_DIR}/../opencv/install"
OPENCV_DIR="${OPENCV_INSTALL_DIR}/lib/cmake/opencv4"

if [ ! -f "${NVDLA_RUNTIME_LIB}" ] || [ ! -f "${NVDLA_COMPILER_LIB}" ]; then
  echo "NVDLA runtime/compiler libraries not found, building nvdla/sw first..."
  "${NVDLA_SW_DIR}/compile.sh"
fi

SYSROOT="$(${TOOLCHAIN_PREFIX}gcc --print-sysroot)"
OPENCV_CMAKE_ARGS=""

if [ -f "${OPENCV_DIR}/OpenCVConfig.cmake" ]; then
  OPENCV_CMAKE_ARGS="-DOpenCV_DIR=${OPENCV_DIR} -DCMAKE_PREFIX_PATH=${OPENCV_INSTALL_DIR}"
  echo "Using OpenCV from ${OPENCV_DIR}"
else
  echo "OpenCV cross package not found at ${OPENCV_DIR}; tm_yolox_opendla may be skipped."
fi

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" \
  -DTENGINE_ENABLE_OPENDLA=ON \
  -DTENGINE_ENABLE_RISCV_LP64DV_OPT=OFF \
  -DTENGINE_BUILD_SHARED=OFF \
  -DTENGINE_OPENMP=OFF \
  -DTENGINE_ONLINE_REPORT=OFF \
  -DNVDLA_SW_ROOT="${NVDLA_SW_DIR}" \
  -DCMAKE_EXE_LINKER_FLAGS="-static -static-libgcc -static-libstdc++ -Wl,--gc-sections" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
  -DCMAKE_LINK_SEARCH_START_STATIC=ON \
  -DCMAKE_LINK_SEARCH_END_STATIC=ON \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=riscv64 \
  -DCMAKE_C_COMPILER="${TOOLCHAIN_PREFIX}gcc" \
  -DCMAKE_CXX_COMPILER="${TOOLCHAIN_PREFIX}g++" \
  -DCMAKE_ASM_COMPILER="${TOOLCHAIN_PREFIX}gcc" \
  -DCMAKE_AR="${TOOLCHAIN_PREFIX}ar" \
  -DCMAKE_RANLIB="${TOOLCHAIN_PREFIX}ranlib" \
  -DCMAKE_STRIP="${TOOLCHAIN_PREFIX}strip" \
  -DCMAKE_SYSROOT="${SYSROOT}" \
  -DCMAKE_FIND_ROOT_PATH="${SYSROOT}" \
  -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
  ${OPENCV_CMAKE_ARGS}

cmake --build "${BUILD_DIR}" --target tm_classification_opendla -j"$(nproc)"

if cmake --build "${BUILD_DIR}" --target help | grep "tm_yolox_opendla" >/dev/null; then
  cmake --build "${BUILD_DIR}" --target tm_yolox_opendla -j"$(nproc)"
else
  echo "Skipping tm_yolox_opendla: target is not generated (OpenCV not found for cross-compile)."
fi

if cmake --build "${BUILD_DIR}" --target help | grep "tm_yolov3_tiny_opendla" >/dev/null; then
  cmake --build "${BUILD_DIR}" --target tm_yolov3_tiny_opendla -j"$(nproc)"
else
  echo "Skipping tm_yolov3_tiny_opendla: target is not generated (OpenCV not found for cross-compile)."
fi
