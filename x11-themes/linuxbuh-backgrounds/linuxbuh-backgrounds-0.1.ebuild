# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=7

inherit eutils

DESCRIPTION="Linuxbuh Backgrounds"
HOMEPAGE="http://linuxbuh.ru"
SRC_URI="ftp://ftp.linuxbuh.ru/linuxbuh/x11-themes/linuxbuh-backgrounds/${P}.tar.gz"

LICENSE="GPL"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror strip"

RDEPEND=""



src_install() {
cd ${WORKDIR}
mkdir -p ${D}/usr/share/backgrounds/xfce
cp -r ${WORKDIR}/${P}/* ${D}/usr/share/backgrounds/xfce
}

pkg_postinst() {
rm /usr/share/backgrounds/xfce/Calculate*
}
