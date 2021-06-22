# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3

DESCRIPTION="USB HASP emulator"
HOMEPAGE="https://github.com/rsvt1973/UsbHasp"
EGIT_REPO_URI="https://github.com/linuxbuh/UsbHasp"

LICENSE=""
SLOT="0"
KEYWORDS=""

IUSE="systemd"

DEPEND="dev-libs/jansson
	sys-libs/libusb-vhci
	systemd? ( sys-apps/systemd )"

src_compile() {
	default
}

src_install() {
	dobin dist/Release/GNU-Linux/usbhasp || die
	newinitd "${FILESDIR}/${PN}.init" "${PN}"
	newconfd "${FILESDIR}/${PN}.conf" "${PN}"
	if use systemd; then
		systemd_newunit ${FILESDIR}/${PN}.service ${PN}.service
	fi
	keepdir /etc/${PN}
}

pkg_postinst(){
	elog
	elog "Post-installation tasks:"
	elog
	elog "1. Put images of USB keys (*.json) in /etc/usbhasp"
	elog "2. Set automatic startup with \`rc-update add ${PN} default\`"
	elog "3. For manual start run \`rc-service ${PN} start\`"
	elog
}
