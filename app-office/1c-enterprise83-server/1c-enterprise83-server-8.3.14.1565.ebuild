# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="Сервер 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-server"

LICENSE="1CEnterprise_en"
KEYWORDS="-* amd64 x86"
RESTRICT="fetch"

SLOT="0"
IUSE="nls postgres fontconfig server"

RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}[${MULTILIB_USEDEP}]
	postgres? ( dev-db/postgresql-1c-pro[pg_legacytimestamp,${MULTILIB_USEDEP}] )
	server? ( app-office/1c-server-utils[${MULTILIB_USEDEP}] )
	fontconfig? ( gnome-extra/libgsf[${MULTILIB_USEDEP}]
			app-text/ttf2pt1[${MULTILIB_USEDEP}]
			media-gfx/imagemagick[corefonts,${MULTILIB_USEDEP}]
			dev-db/unixODBC[${MULTILIB_USEDEP}] )"
#	nls? ( =app-office/1c-enterprise83-client-nls-${PV}:${SLOT}[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

pkg_nofetch() {
    einfo "Please download"
    einfo "  - ${P}.tar.gz"
    einfo "from ${HOMEPAGE} and place them in your DISTDIR directory."
}


src_unpack(){
        unpack_deb ${A}
}

src_install() {
#	dodir /opt
#	mv "${WORKDIR}"/opt/* "${D}"/opt
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!" 

}



