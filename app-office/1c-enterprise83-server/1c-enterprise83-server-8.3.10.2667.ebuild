# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils versionator

DESCRIPTION="Server component of 1C ERP system"
HOMEPAGE="http://v8.1c.ru/"
DOWNLOADPAGE="http://ftp.linuxbuh.ru/1c83/server"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-server"
SRC_URI="x86? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_i386.tar.gz
	    nls? ( $DOWNLOADPAGE/${MY_PN}-nls_${MY_PV}_i386.tar.gz ) )
	amd64? ( $DOWNLOADPAGE/${MY_PN}_${MY_PV}_amd64.tar.gz
	    nls? ( $DOWNLOADPAGE/${MY_PN}-nls_${MY_PV}_amd64.tar.gz ) )"


#SLOT="0"
LICENSE="1CEnterprise_en"
KEYWORDS="amd64 x86"
RESTRICT="mirror strip"

MY_VERSION="$(delete_all_version_separators ${SLOT})"
MY_USER="usr1cv${MY_VERSION}"
MY_GROUP="grp1cv${MY_VERSION}"
#if use x86 ; then
#    MY_LIBDIR="i386"
#elif use amd64 ; then
#    MY_LIBDIR="x86_64"
#fi

#SLOT="$(get_version_component_range 1-2)"
SLOT="0"
IUSE="-postgres -fontconfig -nls -pax_kernel"

RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}
	postgres? ( dev-db/postgresql-server[1c,pg_legacytimestamp] )
	fontconfig? ( gnome-extra/libgsf
			app-text/ttf2pt1
			media-gfx/imagemagick[corefonts]
			dev-db/unixODBC ) "
DEPEND="${RDEPEND}"

S="${WORKDIR}"

#QA_TEXTRELS="opt/1C/v${SLOT}/${MY_LIBDIR}/libociicus.so
#	    opt/1C/v${SLOT}/${MY_LIBDIR}/libnnz10.so
#	    opt/1C/v${SLOT}/${MY_LIBDIR}/libclntsh.so.10.1"

#QA_EXECSTACK="opt/1C/v${SLOT}/${MY_LIBDIR}/libociicus.so
#	    opt/1C/v${SLOT}/${MY_LIBDIR}/libnnz10.so
#	    opt/1C/v${SLOT}/${MY_LIBDIR}/libclntsh.so.10.1"

#pkg_setup() {
#	enewgroup "${MY_GROUP}"
#	enewuser "${MY_USER}" -1 "/bin/bash" "/home/${MY_USER}" "${MY_GROUP}"
#	chown -R ":${MY_GROUP}" "/home/${MY_USER}"
#}

src_prepare() {
	epatch "${FILESDIR}/init.d.patch"
}

#src_install() {
#	if use pax_kernel; then
#	    local binaries=(
#		rphost
#		ragent
#		rmngr
#	    )
#	    cd "${WORKDIR}/opt/1C/v${SLOT}/${MY_LIBDIR}/"
#	    pax-mark m "${binaries[@]}"
#	fi
#	dodir /opt
#	mv "${WORKDIR}"/opt/* "${D}"/opt
#	doinitd "${WORKDIR}/etc/init.d/srv1cv${MY_VERSION}"
#}

#pkg_postinst() {
#	if use fontconfig ; then
#		elog "You can config fonts for 1C ERP system by exec"
#		elog "/opt/1C/v${SLOT}/${MY_LIBDIR}/utils/config_server /path/to/font/dir/corefonts"
#	fi
#	if use postgres ; then
#		elog "Perhaps you should add locale en_US in /etc/localegen and"
#		elog "regenerate locales to use 1C with postgres."
#	fi
#}

src_unpack() {
	    unpack ${A}
	    
}


src_install() {
	dodir /opt
	mv "${WORKDIR}"/opt/* "${D}"/opt
	doinitd "${WORKDIR}/etc/init.d/srv1cv${MY_VERSION}"
}



