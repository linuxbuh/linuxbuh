# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=6

inherit eutils

DESCRIPTION="1C Enterprize Conf Trade Setup"
HOMEPAGE="http://linuxbuh.ru"
SRC_URI="ftp://ftp.linuxbuh.ru/buhsoft/1C/1c83/Conf/trade/${P}.tar.gz"

LICENSE="GPL"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror strip"

RDEPEND=""



src_install() {
cd ${WORKDIR}
mkdir -p ${D}/opt/1C/1c-trade-setup
cp -r ${WORKDIR}/${P}/* ${D}/opt/1C/1c-trade-setup
}

