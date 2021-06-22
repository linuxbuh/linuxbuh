# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit git-r3 autotools

DESCRIPTION="Native C/C++ library of USB Virtual Host Controller Interface"
HOMEPAGE="https://sourceforge.net/p/usb-vhci/wiki/Home/"
EGIT_REPO_URI="https://github.com/linuxbuh/libusb_vhci.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""

IUSE=""

DEPEND="app-emulation/usb-vhci-hcd"

src_prepare() {
    eautoreconf
    default
}
