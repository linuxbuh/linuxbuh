# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="Тонкий Клиент 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-thin-client"

LICENSE="1CEnterprise_en"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="fetch"

SLOT="0"

IUSE="nls"

RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}[${MULTILIB_USEDEP}]
	=app-office/1c-enterprise83-server-${PV}:${SLOT}[${MULTILIB_USEDEP}]
	>=dev-libs/icu-4.6[${MULTILIB_USEDEP}]
	net-libs/webkit-gtk:3[${MULTILIB_USEDEP}]
	app-crypt/mit-krb5[${MULTILIB_USEDEP}]
	media-gfx/imagemagick[${MULTILIB_USEDEP}]
	net-print/cups[${MULTILIB_USEDEP}]
	x11-libs/libSM[${MULTILIB_USEDEP}]
	dev-libs/atk[${MULTILIB_USEDEP}]
	x11-libs/libXxf86vm[${MULTILIB_USEDEP}]
	>=sys-libs/e2fsprogs-libs-1.41[${MULTILIB_USEDEP}]
	>=x11-libs/cairo-1.0[${MULTILIB_USEDEP}]
	sys-libs/glibc:2.2[${MULTILIB_USEDEP}]
	>=sys-devel/gcc-3.4[${MULTILIB_USEDEP}]
	x11-libs/gtk+:2[${MULTILIB_USEDEP}]
	x11-libs/gdk-pixbuf:2[${MULTILIB_USEDEP}]
	dev-libs/glib:2[${MULTILIB_USEDEP}]
	net-libs/libsoup:2.4[${MULTILIB_USEDEP}]
	sys-libs/zlib[${MULTILIB_USEDEP}]"
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
#	dodir /opt /usr
#	mv "${WORKDIR}"/opt/* "${D}"/opt

#	local res
#	for res in 16 22 24 32 36 48 64 72 96 128 192 256; do
#		for icon in 1cestart 1cv8 1cv8c 1cv8s; do
#			newicon -s ${res} "${WORKDIR}/usr/share/icons/hicolor/${res}x${res}/apps/${icon}.png" "${icon}.png"
#		done
#	done


#	domenu "${WORKDIR}"/usr/share/applications/{1cv8,1cv8c,1cestart}.desktop
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!" 
	cp -R "${WORKDIR}/usr" "${D}" || die "install failed!" 

}
