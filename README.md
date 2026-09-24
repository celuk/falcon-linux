# falcon-linux

The software stack of [falcon](https://github.com/gdrlab/falcon), a Linux capable RISC-V SoC with NVDLA for edge AI inference. It contains [OpenSBI](https://github.com/riscv-software-src/opensbi) as first stage bootloader, a 64-bit [linux kernel](https://github.com/torvalds/linux) configured for the SoC, a [BusyBox](https://github.com/mirror/busybox) based initramfs embedded into the kernel image and the [NVDLA software stack](https://github.com/nvdla/sw) (KMD and UMD) ported to RISC-V and Linux 6.15. Everything is compiled as bare images (no U-Boot, no disk, no root filesystem on external media (e.g. SD Card)) and loaded straight into DRAM over UART (or JTAG), so the CVA6 soft-core on the FPGA boots Linux and drives the NVDLA by itself without any hard ARM processing system.

falcon is built on the [Cheshire](https://github.com/pulp-platform/cheshire) platform around a 64-bit CVA6 core (RV64IMAFDC, SV39 MMU) with the `nv_small` configuration of NVDLA and runs on a Xilinx VCU108 board. The hardware, the bitstream flow and the programming scripts are in the main repo: https://github.com/gdrlab/falcon

A similar but smaller 32-bit version of this flow, without NVDLA, is in [riscv-linux-from-scratch](https://github.com/celuk/riscv-linux-from-scratch).

## Requirements

The 64-bit riscv linux toolchain is built from the [riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain) copy in [`riscv-toolchain-custom`](riscv-toolchain-custom) (`riscv64-unknown-linux-gnu-`, rv64gc / lp64d, glibc) and installed into `riscv-toolchain-custom/_install`. Every other build script points to that path relatively, so the toolchain has to be built first. Its host prerequisites are listed in the [riscv-gnu-toolchain README](riscv-toolchain-custom/riscv-gnu-toolchain/README.md).

Also needed: `dtc` for the device tree, `autoconf` for lrzsz, `cmake` for OpenCV and Tengine, `cpio` for the initramfs and `python3` with `pyserial` for programming over UART:

```bash
sudo apt install build-essential autoconf cmake cpio device-tree-compiler
sudo apt install python3 python3-pip
pip3 install pyserial
```

and the scripts in [falcon/cheshire-env-nvdla/tools](https://github.com/gdrlab/falcon/tree/main/cheshire-env-nvdla/tools) ([`bin2hex.py`](https://github.com/gdrlab/falcon/tree/main/cheshire-env-nvdla/tools/bin2hex.py), [`uart_send_data_to_dram.py`](https://github.com/gdrlab/falcon/tree/main/cheshire-env-nvdla/tools/uart_send_data_to_dram.py), [`vmem_to_ddr3_init.py`](https://github.com/gdrlab/falcon/tree/main/cheshire-env-nvdla/tools/vmem_to_ddr3_init.py)).

**Note:** Clone the repo on a case-sensitive filesystem (e.g. ext4, not `/mnt/c` on WSL or NTFS). The kernel and the toolchain linux headers have netfilter headers that only differ in case (e.g. `xt_DSCP.h` and `xt_dscp.h`), which overwrite each other otherwise.

## Directories

| Directory | Version | Description |
| --- | --- | --- |
| [riscv-toolchain-custom](riscv-toolchain-custom) | 2021.01.26 | custom `riscv64-unknown-linux-gnu-` cross compiler used for everything below |
| [riscv-opensbi-port](riscv-opensbi-port) | v1.7 | [`platform/template`](riscv-opensbi-port/platform/template) port for the SoC (8250 UART at `0x3002000` for the SBI console), [`custom.dts`](riscv-opensbi-port/platform/template/custom.dts) device tree with the NVDLA node |
| [riscv-linux-port](riscv-linux-port) | v6.15 | RV64 config [`arch/riscv/configs/64-bit.config`](riscv-linux-port/arch/riscv/configs/64-bit.config) for the SoC, with DRM/GEM DMA helpers and 64 MB CMA for the NVDLA buffers |
| [riscv-busybox-port](riscv-busybox-port) | 1.36.1 | static build and the init script in [`compile.sh`](riscv-busybox-port/compile.sh) that builds the initramfs with the NVDLA driver, runtime, loadables and test images |
| [nvdla/sw](nvdla/sw) | latest | KMD [`opendla.ko`](nvdla/sw/kmd/port/linux) ported to Linux 6.15 and UMD `nvdla_runtime` / `nvdla_compiler` cross-compiled for RISC-V (`DLA_2_CONFIG`, i.e. `nv_small`) |
| [nvdla/loadables](nvdla/loadables) | latest | precompiled `.nvdla` loadables and test images for LeNet-5 (MNIST), ResNet-18 (CIFAR-10) and ResNet-18 (ImageNet-2012) |
| [lrzsz](lrzsz) | 0.13.0-alpha | static `rz` / `sz` to transfer files over the UART console with ZMODEM |
| [opencv](opencv) | 4.2 | static cross build of `core`, `imgproc`, `imgcodecs` and `highgui`, needed by Tengine |
| [tengine](tengine) | lite v1.5 | inference engine with the OpenDLA backend (`tm_classification_opendla`, `tm_yolox_opendla`, `tm_yolov3_tiny_opendla`), experimental and not included in the initramfs by default |

## Compilation

```bash
git clone https://github.com/gdrlab/falcon-linux
```

```bash
cd falcon-linux
```

Build the toolchain first (it takes a while):

```bash
make toolchain
```

Then build the rest:

```bash
make all
```

`make all` runs the steps in this order, because the parts depend on each other (it also handles circular dependency):

```bash
make opensbi   # OpenSBI fw_dynamic + device tree
make lrzsz     # rz / sz
make busybox   # first initramfs (without the NVDLA driver)
make linux     # first kernel, needed as KDIR for the out-of-tree KMD
make nvdla     # opendla.ko, nvdla_runtime, nvdla_compiler
make busybox   # initramfs again, now with opendla.ko and nvdla_runtime
make linux     # final kernel with the final initramfs embedded
```

Optionally (not part of `make all`):

```bash
make opencv
make tengine
```

Every directory has its own `compile.sh` with the exact commands. Some paths in them are left as absolute local paths, so fix them for your machine before running them.

[`riscv-busybox-port/compile.sh`](riscv-busybox-port/compile.sh) uses `sudo` for `mknod` of `/dev/console` and `/dev/null` in the initramfs.

## Running

Generated hex files to program:

```bash
riscv-opensbi-port/platform/template/custom.dtb.hex
```

```bash
riscv-linux-port/arch/riscv/boot/Image.hex
```

```bash
riscv-opensbi-port/build/platform/template/firmware/fw_dynamic.hex
```

--> You can program these hex codes separately to their DRAM addresses as it is done in the [falcon Makefile](https://github.com/gdrlab/falcon/blob/main/Makefile) `program_linux` make command (program bitstream, send dtb, kernel and OpenSBI over UART at 921600 baud) to run linux on the pure soft-core SoC running on the FPGA:

```bash
make program_linux <ttyUSB number>
```

Then open the console (115200 baud):

```bash
make pico <ttyUSB number>
```

Over JTAG, the same can be done with OpenOCD + GDB using [`load_fw.gdb`](https://github.com/gdrlab/falcon/blob/main/util/load_fw.gdb), which restores `custom.dtb` and `Image` as binaries and loads `fw_dynamic.elf`.

## Running Models on NVDLA

At boot, `/etc/init.d/rcS` mounts `devtmpfs`, `proc` and `sysfs` and loads `opendla.ko`. You can then run the models from the shell in the linux console over UART with `nvdla_runtime` and `.nvdla` loadables generated by `nvdla_compiler`:

```
Starting shell...
~ # nvdla_runtime --image 0_8.jpg --loadable lenet-fast-math.nvdla --rawdump
~ # nvdla_runtime --image cat_32.jpg --loadable cifar-default.nvdla --rawdump
~ # nvdla_runtime --image 331_hare.jpg --loadable imagenet-default.nvdla --rawdump
```

| Model | Dataset | Loadable | Input | Test image in initramfs |
| --- | --- | --- | --- | --- |
| LeNet-5 | MNIST | [`lenet-fast-math.nvdla`](nvdla/loadables/lenet) | 28x28 | `0_8.jpg` |
| ResNet-18 | CIFAR-10 | [`cifar-default.nvdla`](nvdla/loadables/resnet18-cifar10) | 32x32 | `cat_32.jpg` |
| ResNet-18 | ImageNet-2012 | [`imagenet-default.nvdla`](nvdla/loadables/resnet18-imagenet2012) | 224x224 | `331_hare.jpg` |

More test images are in the `images` directories of [`nvdla/loadables`](nvdla/loadables). To try another image or loadable without rebuilding the kernel, send it over the console from picocom using [`lrzsz`](https://github.com/UweOhse/lrzsz) tools built:

```bash
# install lrzsz on your host too if not installed (it is installed already in the target)
sudo apt install lrzsz
```

```bash
# sending file from host (your PC) to target (softcore on FPGA) over UART
## while you are in linux bash shell over UART in picocom terminal press CTRL+A CTRL+S
## give the path of the file in the host and press enter to send
## the target will automatically receive the file by running sz on the host and rz on the target
## if the file is binary you may use uuencode in your host to convert encoded txt file and can decode with uudecode on the target to get original file
```

```bash
# sending file from target (softcore on FPGA) to host (your PC) over UART
## while you are in linux bash shell over UART in picocom terminal, type the path of the file in the host with sz command
sz <file-to-send> ## keep one empty space character after this command
## press enter to send (in some terminals even you shouldn't press, you can try both and see which one is working)
## press CTRL+A CTRL+R
## it will ask for file but do not type anything just press enter
## the host will automatically receive the file by running rz on the host
## if the file is binary you may use uuencode in your target to convert encoded txt file and can decode with uudecode on the host to get original file
```

or add it to the `cp` lines in [`riscv-busybox-port/compile.sh`](riscv-busybox-port/compile.sh) and rebuild BusyBox and Linux.

ImageNet ResNet-18 needs large contiguous DMA buffers, which is why the kernel is built with 64 MB CMA (`CONFIG_CMA_SIZE_MBYTES=64`, and `cma=64M` in the device tree bootargs). With a smaller CMA pool it crashes while allocating the buffers.

## Boot Process

![linux_boot_process.png](figures/linux_boot_process.png)

A modified zero stage bootloader in the Cheshire bootrom runs in M mode, hands control to OpenSBI in DRAM, OpenSBI does the M mode setup and drops to S mode at the linux entry point. The kernel takes the device tree pointer it was given, unpacks the initramfs that is linked into its own image, runs BusyBox `/init` in U mode and loads `opendla.ko`, which probes the `nvdla@40000000` node of the device tree and registers its PLIC interrupt. No second stage bootloader and no block device are involved.

The DRAM base of the SoC is `0x80000000` (2 GB DDR4) and the three images are placed like this:

| Image | Offset from DRAM base | Absolute address |
| --- | --- | --- |
| OpenSBI `fw_dynamic.bin` | `0x00000000` | `0x80000000` |
| Device tree `custom.dtb` | `0x00140000` | `0x80140000` |
| Linux `Image` (kernel + initramfs + loadables) | `0x00200000` | `0x80200000` |

The device tree region is kept out of the linux memory with `/memreserve/ 0x80140000 0x00010000` in [`custom.dts`](riscv-opensbi-port/platform/template/custom.dts). These offsets are the ones in the modified [`cheshire_bootrom.c`](https://github.com/gdrlab/falcon/blob/main/cheshire-env-nvdla/cheshire/hw/bootrom/cheshire_bootrom.c), in the `program_linux` command of the [falcon `Makefile`](https://github.com/gdrlab/falcon/blob/main/Makefile) and in [`load_fw.gdb`](https://github.com/gdrlab/falcon/blob/main/util/load_fw.gdb). If you change one, change the others as well.

## FW_DYNAMIC bootloader

OpenSBI can be built three ways. `FW_JUMP` has the next stage address compiled in, `FW_PAYLOAD` embeds the kernel inside the firmware binary itself, and `FW_DYNAMIC` is told at runtime where to go next. This repo uses `FW_DYNAMIC`, so the kernel and the device tree stay separate files that can be loaded or replaced on their own without rebuilding OpenSBI.

The price is that `FW_DYNAMIC` will not boot on its own. The previous stage has to fill a `fw_dynamic_info` struct and enter OpenSBI with `a0 = hartid`, `a1 = dtb address` and `a2 = pointer to that struct`. A bootloader that does not do this will hand OpenSBI garbage in `a2` and the boot dies before any console output.

The original Cheshire bootrom only jumps to an entry point, so the falcon bootrom is modified to do this in [`cheshire_bootrom.c`](https://github.com/gdrlab/falcon/blob/main/cheshire-env-nvdla/cheshire/hw/bootrom/cheshire_bootrom.c):

```c
struct fw_dynamic_info {
    unsigned long magic; // uint64_t
    unsigned long version;
    unsigned long next_addr;
    unsigned long next_mode;
    unsigned long options;
    unsigned long boot_hart;
};
```

```c
dynamic_info.magic     = 0x4942534f; // magic word "OSBI"
dynamic_info.version   = 0x2;
dynamic_info.next_addr = 0x80000000 + 0x00200000; // linux Image pointer
dynamic_info.next_mode = 0x1; // S mode
dynamic_info.options   = 0x0;
dynamic_info.boot_hart = 0x0;
```

```c
__asm__ volatile (
    "mv a0, %[hart_id]\n"
    "mv a1, %[dtb_addr]\n" // 0x80000000 + 0x00140000
    "mv a2, %[info_addr]\n" // &dynamic_info
);
// then jump to 0x80000000 (OpenSBI)
```

Note that the struct fields are `unsigned long` (64-bit) on RV64, and `next_mode` is `1` (S mode), not `3`. If you set it to M mode the kernel starts with the wrong privilege level and traps as soon as it touches an S mode CSR.

If your SoC instead has a bootloader that only jumps to a fixed address, build with `FW_JUMP=y FW_JUMP_ADDR=0x80200000 FW_JUMP_FDT_ADDR=0x80140000`, or use `FW_PAYLOAD=y FW_PAYLOAD_PATH=../riscv-linux-port/arch/riscv/boot/Image` (the payload offset is already `0x200000` for RV64 in [`objects.mk`](riscv-opensbi-port/platform/template/objects.mk)) to get a single blob.

## Code References

In addition to the upstream projects above, some codes were used from these repos directly or after some modification:

https://github.com/nvdla/sw

https://github.com/pulp-platform/cheshire

https://github.com/LeiWang1999/ZYNQ-NVDLA

https://github.com/OAID/Tengine
