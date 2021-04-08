# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

inherit eutils

DESCRIPTION="A high-quality scanning and digital camera raw image processing software."
HOMEPAGE="http://www.hamrick.com/"
DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/linuxbuh/vuescan"
SRC_URI="abi_x86_64? ( $DOWNLOADPAGE/vuex6497.tgz )"

LICENSE="vuescan"
SLOT="0"
KEYWORDS="amd64"
RESTRICT="mirror strip"

S="${WORKDIR}/VueScan"

INSTALLDIR="/opt/VueScan"

IUSE=""

RDEPEND=">=x11-libs/gtk+-2.0
	virtual/libusb:0
	media-gfx/sane-backends"

DEPEND="${RDEPEND}"

#S="${WORKDIR}"

src_install() {
	dodir /opt
	cp -a "${WORKDIR}"/VueScan "${D}"/opt || die

	into /opt

	exeinto /usr/bin
	doexe ${FILESDIR}/vuescan

mkdir -p ${D}/usr/share/applications
mkdir -p ${D}/usr/share/pixmaps

cp -r ${FILESDIR}/vuescan.desktop ${D}/usr/share/applications/vuescan.desktop
cp -r ${FILESDIR}/*.svg ${D}/usr/share/pixmaps


}

pkg_postinst() {
	einfo "To use scanner with Vuescan under user you need add user into scanner group."
	einfo "Just run under root: gpasswd -a username scanner"
}

