# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=7

inherit fdo-mime font eutils

DESCRIPTION="basilisk webrowser"
HOMEPAGE="https://www.basilisk-browser.org/"

KEYWORDS="~amd64"

SRC_URI="
    amd64? ( https://eu.basilisk-browser.org/release/basilisk-latest.linux64.tar.xz )
    "

SLOT="0"
RESTRICT="strip mirror"
LICENSE="AGPL-3"
IUSE=""


NATIVE_DEPEND=""
RDEPEND="
    ${NATIVE_DEPEND}
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {
#	cd ${WORKDIR}
	mkdir -p ${D}/opt/basilisk
	cp -R ${WORKDIR}/basilisk/* ${D}/opt/basilisk
	mkdir -p ${D}/usr/share/applications
	mkdir -p ${D}/usr/share/pixmaps
	cp -r ${FILESDIR}/basilisk-browser.desktop ${D}/usr/share/applications/basilisk-browser.desktop
	cp -r ${FILESDIR}/*.png ${D}/usr/share/pixmaps

}

