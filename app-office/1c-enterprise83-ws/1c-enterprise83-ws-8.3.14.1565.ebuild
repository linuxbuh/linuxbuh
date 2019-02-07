# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="WEB Сервер 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-ws"

LICENSE="1CEnterprise_en"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="fetch"

SLOT="0"

IUSE="nls"

RDEPEND="=app-office/1c-enterprise83-server-${PV}:${SLOT}[${MULTILIB_USEDEP}]"
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
	dodir /opt
	mv "${WORKDIR}"/opt/* "${D}"/opt
}

pkg_postinst() {
	elog "You need to configure fonts for the web compoment of 1C ERP system by exec"
	if use x86 ; then
	    elog "/opt/1C/v83/i386/utils/config_server /usr/share/fonts/corefont"
	elif use amd64 ; then
	    elog "/opt/1C/v83/x86_64/utils/config_server /usr/share/fonts/corefont"
	fi
	elog "or you may get an error \"Failed to initialize graphics subsystem!\""
}