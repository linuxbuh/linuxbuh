# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker


DESCRIPTION="Base component of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"
DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/buhsoft/1C/1c83/client_server"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-common"

SRC_URI="abi_x86_32? ( $DOWNLOADPAGE/1c-enterprise83-common_8.3.10-2772_i386.deb )
	abi_x86_64? ( $DOWNLOADPAGE/1c-enterprise83-common_8.3.10-2772_amd64.deb )"


SLOT="0"
LICENSE="1CEnterprise_en"
KEYWORDS="-* amd64 x86"
RESTRICT="mirror strip"

IUSE="nls"

RDEPEND=">=sys-libs/glibc-2.3[${MULTILIB_USEDEP}]
	>=dev-libs/icu-3.8.1-r1[${MULTILIB_USEDEP}]"
#	nls? ( =app-office/1c-enterprise83-client-nls-${PV}:${SLOT}[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_unpack(){
        unpack_deb ${A}
}


src_install() {
#	dodir /opt
#	mv "${WORKDIR}"/opt/* "${D}"/opt
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!" 

}
