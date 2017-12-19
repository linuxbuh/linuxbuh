# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils multilib flag-o-matic versionator

DESCRIPTION="Base component of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"
DOWNLOADPAGE="http://ftp.linuxbuh.ru/1c83/server"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-common"
#if use x86 ; then
#    MY_LIBDIR="i386"
#elif use amd64 ; then
#    MY_LIBDIR="x86_64"
#fi

SRC_URI="x86? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_i386.tar.gz
	    nls? ( $DOWNLOADPAGE/${MY_PN}-nls_${MY_PV}_i386.tar.gz ) )
	amd64? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_amd64.tar.gz
	    nls? ( $DOWNLOADPAGE/${MY_PN}-nls_${MY_PV}_amd64.tar.gz ) )"


SLOT="0"
LICENSE="1CEnterprise_en"
KEYWORDS="amd64 x86"
RESTRICT="mirror strip"
IUSE="nls"

RDEPEND=">=sys-libs/glibc-2.3
	>=dev-libs/icu-3.8.1-r1"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

#QA_TEXTRELS="opt/1C/v${SLOT}/${MY_LIBDIR}/backbas.so"
#QA_EXECSTACK="opt/1C/v${SLOT}/${MY_LIBDIR}/backbas.so"

src_unpack() {
	    unpack ${A}
	    
}


src_install() {
	dodir /opt
	mv "${WORKDIR}"/opt/* "${D}"/opt
}
