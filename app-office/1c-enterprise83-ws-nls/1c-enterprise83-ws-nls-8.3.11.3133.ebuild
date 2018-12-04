# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )
 
inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="Web component of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"

DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/buhsoft/1C/1c83/client_server"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-ws-nls"
SRC_URI="abi_x86_32? ( $DOWNLOADPAGE/1c-enterprise83-ws-nls_8.3.11-3133_i386.deb )
	abi_x86_64? ( $DOWNLOADPAGE/1c-enterprise83-ws-nls_8.3.11-3133_amd64.deb )"


LICENSE="1CEnterprise_en"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="mirror strip"

SLOT="0"

IUSE=""

RDEPEND="=app-office/1c-enterprise83-ws-${PV}:${SLOT}[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

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
	if use pax_kernel ; then
	    elog ""
	    elog "You may have to disable MPROTECT for the /usr/sbin/apache2 binary"
	    elog "Otherwise, the PAX-kernel will not allow the web-server to work"
	    elog "with 1C web-component apache module."
	fi
}
