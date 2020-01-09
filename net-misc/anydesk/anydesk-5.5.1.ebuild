# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION="All-In-One Solution for Remote Access and Support over the Internet"
HOMEPAGE="http://anydesk.com/"
SRC_URI="
        x86?   ( http://download.anydesk.com/linux/${P}-i386.tar.gz )
        amd64? ( http://download.anydesk.com/linux/${P}-amd64.tar.gz )"

LICENSE=""
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND="x11-libs/gtkglext"
RDEPEND="${DEPEND}"

src_install() {
    dobin anydesk
    mkdir -p ${D}/usr/share/applications
    mkdir -p ${D}/usr/share/pixmaps

    cp -r ${FILESDIR}/anydesk.desktop ${D}/usr/share/applications/anydesk.desktop
    cp -r ${FILESDIR}/*.svg ${D}/usr/share/pixmaps

}
