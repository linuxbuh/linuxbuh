# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=6

inherit eutils

DESCRIPTION="x11vnc autostart in lighdm CLDX"
HOMEPAGE="http://linuxbuh.ru"
SRC_URI="ftp://ftp.linuxbuh.ru/linuxbuh/x11vnc/${P}.tar.gz"

LICENSE="GPL"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE=""

RESTRICT="mirror strip"

RDEPEND="x11-misc/x11vnc
	x11-misc/lightdm"



src_install() {
cd ${WORKDIR}
mkdir -p ${D}/etc/lightdm
mkdir -p ${D}/etc/x11vnc
mkdir -p ${D}/usr/bin
cp -r ${WORKDIR}/${P}/lightdm/lightdm.conf.nox11vnc ${D}/etc/lightdm
cp -r ${WORKDIR}/${P}/lightdm/lightdm.conf ${D}/etc/lightdm
cp -r ${WORKDIR}/${P}/x11vnc/passwd ${D}/etc/x11vnc
cp -r ${WORKDIR}/${P}/x11vnc.sh ${D}/usr/bin
}

pkg_postinst() {
mv /etc/lightdm/lightdm.conf.nox11vnc /etc/lightdm/lightdm.conf.old
}

src_postrm() {
mv /etc/lightdm/lightdm.conf.old /etc/lightdm/lightdm.conf
}
