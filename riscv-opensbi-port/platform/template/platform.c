// This file is part of https://github.com/gdrlab/falcon-linux
// Copyright (C) 2026  Seyyid Hikmet Celik
//                     seyyid4091@gmail.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#include <sbi/riscv_asm.h>
#include <sbi/riscv_encoding.h>
#include <sbi/riscv_io.h>
#include <sbi/sbi_console.h>
#include <sbi/sbi_const.h>
#include <sbi/sbi_hart.h>
#include <sbi/sbi_platform.h>
#include <libfdt.h>
#include <sbi_utils/fdt/fdt_helper.h>
#include <sbi_utils/fdt/fdt_fixup.h>
#include <sbi_utils/ipi/aclint_mswi.h>
#include <sbi_utils/irqchip/plic.h>
#include <sbi_utils/serial/uart8250.h>
#include <sbi_utils/timer/aclint_mtimer.h>

#define ARIANE_UART_ADDR			0x3002000
#define ARIANE_UART_FREQ			50000000
#define ARIANE_UART_BAUDRATE			115200
#define ARIANE_UART_REG_SHIFT			2
#define ARIANE_UART_REG_WIDTH			4
#define ARIANE_PLIC_ADDR			0x4000000
#define ARIANE_PLIC_NUM_SOURCES			64
#define ARIANE_HART_COUNT			1
#define ARIANE_CLINT_ADDR			0x2040000
#define ARIANE_ACLINT_MTIMER_FREQ		1000000
#define ARIANE_ACLINT_MSWI_ADDR			(ARIANE_CLINT_ADDR + \
						 CLINT_MSWI_OFFSET)
#define ARIANE_ACLINT_MTIMER_ADDR		(ARIANE_CLINT_ADDR + \
						 CLINT_MTIMER_OFFSET)

static struct plic_data plic = {
	.addr = ARIANE_PLIC_ADDR,
	.num_src = ARIANE_PLIC_NUM_SOURCES,
	.flags = PLIC_FLAG_ARIANE_BUG,
};

static struct aclint_mswi_data mswi = {
	.addr = ARIANE_ACLINT_MSWI_ADDR,
	.size = ACLINT_MSWI_SIZE,
	.first_hartid = 0,
	.hart_count = ARIANE_HART_COUNT,
};

static struct aclint_mtimer_data mtimer = {
	.mtime_freq = ARIANE_ACLINT_MTIMER_FREQ,
	.mtime_addr = ARIANE_ACLINT_MTIMER_ADDR +
		      ACLINT_DEFAULT_MTIME_OFFSET,
	.mtime_size = ACLINT_DEFAULT_MTIME_SIZE,
	.mtimecmp_addr = ARIANE_ACLINT_MTIMER_ADDR +
			 ACLINT_DEFAULT_MTIMECMP_OFFSET,
	.mtimecmp_size = ACLINT_DEFAULT_MTIMECMP_SIZE,
	.first_hartid = 0,
	.hart_count = ARIANE_HART_COUNT,
	.has_64bit_mmio = 1,
};

/*
 * Initialize the ariane console.
 */
static int ariane_console_init(void)
{
	return uart8250_init(ARIANE_UART_ADDR,
			     ARIANE_UART_FREQ,
			     ARIANE_UART_BAUDRATE,
			     ARIANE_UART_REG_SHIFT,
			     ARIANE_UART_REG_WIDTH,
			     0,
			     0);
}

/*
 * Ariane platform early initialization.
 */
static int ariane_early_init(bool cold_boot)
{
	if(!cold_boot)
		return 0;

	return ariane_console_init();
}

/*
 * Ariane platform final initialization.
 */
static int ariane_final_init(bool cold_boot)
{
	void *fdt;
	int noff;
	int err;

	if (!cold_boot)
		return 0;

	fdt = (void *)fdt_get_address();

	/* Run generic fixups first so the FDT has room for new properties */
	fdt_fixups(fdt);

	noff = fdt_path_offset(fdt, "/soc/interrupt-controller@4000000");
	if (noff < 0) {
		sbi_printf("Platform fixup: PLIC node not found (err=%d)\n", noff);
	}
	else {
		/* Use the helper to write a single-cell u32 property */
		err = fdt_setprop_u32(fdt, noff, "riscv,ndev", ARIANE_PLIC_NUM_SOURCES);
		if (err < 0) {
			sbi_printf("Platform fixup: failed to set riscv,ndev (err=%d)\n", err);
		}
		//else {
		//	sbi_printf("Platform fixup: successfully set riscv,ndev to %d\n", ARIANE_PLIC_NUM_SOURCES);
		//}
	}

	return 0;
}

/*
 * Initialize the ariane interrupt controller for current HART.
 */
static int ariane_irqchip_init(void)
{
	return plic_cold_irqchip_init(&plic);
}

/*
 * Initialize IPI for current HART.
 */
static int ariane_ipi_init(void)
{
	return aclint_mswi_cold_init(&mswi);
}

/*
 * Initialize ariane timer for current HART.
 */
static int ariane_timer_init(void)
{
	return aclint_mtimer_cold_init(&mtimer, NULL);
}

/*
 * Platform descriptor.
 */
const struct sbi_platform_operations platform_ops = {
	.early_init = ariane_early_init,
	.final_init = ariane_final_init,
	.irqchip_init = ariane_irqchip_init,
	.ipi_init = ariane_ipi_init,
	.timer_init = ariane_timer_init,
};

const struct sbi_platform platform = {
	.opensbi_version = OPENSBI_VERSION,
	.platform_version = SBI_PLATFORM_VERSION(0x0, 0x00),
	.name = "Cheshire SOC",
	.features = SBI_PLATFORM_DEFAULT_FEATURES,
	.hart_count = ARIANE_HART_COUNT,
	.hart_stack_size = SBI_PLATFORM_DEFAULT_HART_STACK_SIZE,
	.heap_size = SBI_PLATFORM_DEFAULT_HEAP_SIZE(1),
	.platform_ops_addr = (unsigned long)&platform_ops
};