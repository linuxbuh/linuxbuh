# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal

DESCRIPTION="A high-quality scanning and digital camera raw image processing software."
HOMEPAGE="http://www.hamrick.com/"
DOWNLOADPAGE="http://ftp.linuxbuh.ru/linuxbuh/vuescan"
SRC_URI="abi_x86_32? ( $DOWNLOADPAGE/vuex3296.tgz )
	abi_x86_64? ( $DOWNLOADPAGE/vuex6496.tgz )"

LICENSE="vuescan"
SLOT="0"
KEYWORDS="-* amd64 x86"
RESTRICT="mirror strip"

S="${WORKDIR}/VueScan"

INSTALLDIR="/opt/VueScan"

IUSE=""

RDEPEND=">=x11-libs/gtk+-2.0[${MULTILIB_USEDEP}]
	media-gfx/sane-backends[${MULTILIB_USEDEP}]"

DEPEND="${RDEPEND}"

#S="${WORKDIR}"

src_install() {
	dodir /opt
	cp -a "${WORKDIR}"/VueScan "${D}"/opt || die

	into /opt

	exeinto /usr/bin
	doexe ${FILESDIR}/vuescan

	doicon ${FILESDIR}/vuescan.svg

	make_desktop_entry vuescan vuescan.svg Graphics


}

pkg_postinst() {
	einfo "To use scanner with Vuescan under user you need add user into scanner group."
	einfo "Just run under root: gpasswd -a username scanner"
}

