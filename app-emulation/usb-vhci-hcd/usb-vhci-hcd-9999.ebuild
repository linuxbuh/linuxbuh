# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 linux-mod

DESCRIPTION="Linux kernel module of USB Virtual Host Controller Interface"
HOMEPAGE="https://sourceforge.net/p/usb-vhci/wiki/Home/"
EGIT_REPO_URI="https://github.com/linuxbuh/vhci_hcd.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""

IUSE=""

MODULE_NAMES="usb-vhci-hcd(usb:${S}:${S}) usb-vhci-iocifc(usb:${S}:${S})"
BUILD_TARGETS="default"

src_prepare() {
	set_arch_to_kernel
	KV="${KV_MAJOR}"."${KV_MINOR}"."${KV_PATCH}"
	mkdir -p "${S}"/linux/"${KV}"/drivers/usb/core
	cp "${KV_DIR}"/include/linux/usb/hcd.h "${S}"/linux/"${KV}"/drivers/usb/core/
	default
}

src_compile() {
	set_arch_to_kernel
	emake KVERSION="${KV_FULL}" KSRC="${KERNEL_DIR}"
}

src_install() {
	set_arch_to_kernel
	linux-mod_src_install
	insinto /etc/modules-load.d
	newins - usb-vhci.conf <<- EOF
		usb-vhci-hcd
		usb-vhci-iocifc
	EOF
	insinto /usr/include/linux
	doins *.h
}

pkg_postinst() {
	elog "For loading modules automatically was installed /etc/modules-load.d/usb-vhci.conf"
}
