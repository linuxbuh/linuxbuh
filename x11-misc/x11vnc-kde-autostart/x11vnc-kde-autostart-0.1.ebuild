# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=7

inherit eutils

DESCRIPTION="x11vnc autostart KDE"
HOMEPAGE="http://linuxbuh.ru"

LICENSE="GPL"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE=""

RESTRICT="mirror strip"

RDEPEND="x11-misc/x11vnc
	x11-misc/sddm"

DEPEND="${RDEPEND}"

S="${WORKDIR}"


src_install() {
cd ${WORKDIR}
mkdir -p ${D}/etc/local.d
mkdir -p ${D}/etc/x11vnc
cp -r ${FILESDIR}/passwd ${D}/etc/x11vnc
cp -r ${FILESDIR}/x11vnc.start ${D}/etc/local.d
}
