# Perry Weather -- arm the i.MX6ULL WDOG1 watchdog before booting Linux.
#
# See VUL-228. U-Boot 2018.03 for this board is built without CONFIG_WDT /
# CONFIG_CMD_WDT, so there is no `wdt` command; we program WDOG1 directly.
#
# This cannot live in uEnv.txt: mx6ul_mx7_install_debian.sh rewrites that file
# per-device (an I2C probe for the WM8904 codec picks fdt_file), so its
# contents differ across units.
#
# WDOG1 @ 0x020bc000 (all registers 16-bit)
#   0x00 WCR  control      0x02 WSR  service      0x08 WMCR misc
#
# WCR bits:
#   [15:8] WT    timeout = (WT + 1) * 0.5 s   -> 0xFF = 128 s (hardware max)
#   [5]    WDA   1 = do not assert WDOG_B under software control
#   [4]    SRS   1 = do not assert system reset under software control
#   [3]    WRE   0 = internal chip reset on timeout. MUST stay 0: this carrier
#                repurposes the WDOG_B pin for the ADC, which is why the DTS
#                deletes fsl,ext-reset-output from &wdog1.
#   [2]    WDE   1 = enable. WRITE ONCE -- cannot be cleared until the next reset.
#   [0]    WDZST 1 = suspend the counter in low-power mode. WRITE ONCE, and the
#                kernel's imx2_wdt_setup() never runs on the already-running
#                path, so we must set it here or it can never be set.
#   => 0xFF35
#
# Linux imx2_wdt_probe() detects WCR.WDE, sets WDOG_HW_RUNNING and reprograms
# WT to its 60 s default; the watchdog core then pings until java-server opens
# /dev/watchdog0. Nothing here needs to hand off explicitly.
#
# Escape hatch: `setenv wdog_disable yes; saveenv` at the U-Boot prompt (this
# script runs after bootdelay, so you can always interrupt) or `fw_setenv
# wdog_disable yes` from Linux.

if test "${wdog_disable}" = "yes"; then
	echo "WDOG1: not armed (wdog_disable=yes)"
else
	mw.w 0x020bc008 0x0000
	mw.w 0x020bc000 0xff35
	mw.w 0x020bc002 0x5555
	mw.w 0x020bc002 0xaaaa
	echo "WDOG1: armed, 128s"
fi

# Resume the stock boot path from CONFIG_BOOTCOMMAND. U-Boot sources boot.scr
# *instead of* loadimage/mmcboot, so the script has to do the boot itself.
# uEnv.txt was already imported before this script was sourced, so fdt_file
# and kernelargs set there are honoured.
if run loadimage; then
	run mmcboot
else
	run netboot
fi
