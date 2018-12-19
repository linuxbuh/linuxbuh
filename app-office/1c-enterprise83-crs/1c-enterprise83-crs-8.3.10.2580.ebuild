# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker


DESCRIPTION="Configurations Storage component of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"
DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/buhsoft/1C/1c83/client_server"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-crs"
SRC_URI="abi_x86_32? ( $DOWNLOADPAGE/1c-enterprise83-crs_8.3.10-2580_i386.deb )"


LICENSE="1CEnterprise_en"
KEYWORDS="-* ~x86"
RESTRICT="mirror strip"

SLOT="0"


RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}[${MULTILIB_USEDEP}]
	=app-office/1c-enterprise83-server-${PV}:${SLOT}[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_unpack(){
        unpack_deb ${A}
}

src_install() {
	dodir /opt
	mv "${WORKDIR}"/opt/* "${D}"/opt
}
