# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="6"

#MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib-minimal

DESCRIPTION="Server component of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"
DOWNLOADPAGE="http://ftp.linuxbuh.ru/1c83/server"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-server"
SRC_URI="x86? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_i386.tar.gz )
	amd64? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_amd64.tar.gz )"


LICENSE="1CEnterprise_en"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="mirror strip"

SLOT="0"
IUSE="postgres fontconfig -nls"

RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}[${MULTILIB_USEDEP}]
	postgres? ( dev-db/postgresql-server[1c,pg_legacytimestamp,${MULTILIB_USEDEP}] )
	fontconfig? ( gnome-extra/libgsf[${MULTILIB_USEDEP}]
			app-text/ttf2pt1[${MULTILIB_USEDEP}]
			media-gfx/imagemagick[corefonts,${MULTILIB_USEDEP}]
			dev-db/unixODBC[${MULTILIB_USEDEP}] )
	nls? ( =app-office/1c-enterprise83-client-nls-${PV}:${SLOT}[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {
	dodir /opt
	mv "${WORKDIR}"/opt/* "${D}"/opt
}



