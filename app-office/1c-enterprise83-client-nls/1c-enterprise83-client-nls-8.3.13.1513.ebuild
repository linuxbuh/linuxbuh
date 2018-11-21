# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal

DESCRIPTION="Native linux client of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"
DOWNLOADPAGE="http://ftp.linuxbuh.ru/buhsoft/1C/1c83/client_server"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-client-nls"
SRC_URI="x86? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_i386.tar.gz )
	amd64? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_amd64.tar.gz )"

LICENSE="1CEnterprise_en"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="mirror strip"

SLOT="0"

IUSE=""

RDEPEND="=app-office/1c-enterprise83-client-${PV}:${SLOT}[${MULTILIB_USEDEP}]"

DEPEND="${RDEPEND}"

S="${WORKDIR}"


src_unpack() {
	    unpack ${A}
	    
}


src_install() {
	dodir /opt /usr
	mv "${WORKDIR}"/opt/* "${D}"/opt
}

