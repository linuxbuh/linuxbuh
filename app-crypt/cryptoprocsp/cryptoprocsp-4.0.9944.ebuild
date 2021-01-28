# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=6

inherit eutils versionator unpacker

DESCRIPTION="Cryptopro package"
HOMEPAGE="http://www.cryptopro.ru"

DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/linuxbuh/app-crypt/cryptoprocsp"

SRC_URI="$DOWNLOADPAGE/${P}.tar.gz"

LICENSE="cryptopro"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RESTRICT="mirror"

S="${WORKDIR}"

src_install() {
cd ${WORKDIR}
mkdir -p ${D}/lib64
mkdir -p ${D}/etc
mkdir -p ${D}/opt
mkdir -p ${D}/tmp
mkdir -p ${D}/usr
mkdir -p ${D}/var
cp -r ${WORKDIR}/${P}/lib64 ${D}
cp -r ${WORKDIR}/${P}/etc ${D}
cp -r ${WORKDIR}/${P}/opt ${D}
cp -r ${WORKDIR}/${P}/tmp ${D}
cp -r ${WORKDIR}/${P}/usr ${D}
cp -r ${WORKDIR}/${P}/var ${D}
}
