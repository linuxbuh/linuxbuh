# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils versionator

DESCRIPTION="Native linux thin client of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"
DOWNLOADPAGE="http://ftp.linuxbuh.ru/1c83/client"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-thin-client"
SRC_URI="x86? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_i386.tar.gz
	    nls? ( $DOWNLOADPAGE/${MY_PN}-nls_${MY_PV}_i386.tar.gz ) )
	amd64? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_amd64.tar.gz
	    nls? ( $DOWNLOADPAGE/${MY_PN}-nls_${MY_PV}_amd64.tar.gz ) )"

LICENSE="1CEnterprise_en"
KEYWORDS="amd64 x86"
RESTRICT="mirror strip"

#SLOT=$(get_version_component_range 1-2)
SLOT="0"

IUSE="-nls"

RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}
	=app-office/1c-enterprise83-server-${PV}:${SLOT}
	>=dev-libs/icu-4.6
	net-libs/webkit-gtk:2
	app-crypt/mit-krb5
	media-gfx/imagemagick
	net-print/cups
	x11-libs/libSM
	dev-libs/atk
	x11-libs/libXxf86vm
	>=sys-libs/e2fsprogs-libs-1.41
	>=x11-libs/cairo-1.0
	sys-libs/glibc:2.2
	>=sys-devel/gcc-3.4
	x11-libs/gtk+:2
	x11-libs/gdk-pixbuf:2
	dev-libs/glib:2
	net-libs/libsoup:2.4
	sys-libs/zlib"

DEPEND="${RDEPEND}"

S="${WORKDIR}"


src_unpack() {
	    unpack ${A}
	    
}


src_install() {
	dodir /opt /usr
	mv "${WORKDIR}"/opt/* "${D}"/opt
	local res
	for res in 16 22 24 32 36 48 64 72 96 128 192 256; do
		for icon in 1cv8c; do
			newicon -s ${res} "${WORKDIR}/usr/share/icons/hicolor/${res}x${res}/apps/${icon}.png" "${icon}.png"
		done
	done


	domenu "${WORKDIR}"/usr/share/applications/{1cv8c}.desktop
}

