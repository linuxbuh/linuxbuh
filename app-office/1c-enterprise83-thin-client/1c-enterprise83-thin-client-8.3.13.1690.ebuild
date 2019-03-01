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
SRC_URI="abi_x86_32? ( ${MY_PN}_${MY_PV}_i386.tar.gz )
	abi_x86_64? ( ${MY_PN}_${MY_PV}_amd64.tar.gz )"

LICENSE="1CEnterprise_en"
KEYWORDS="amd64 x86"
RESTRICT="fetch"

SLOT="0"

IUSE="nls"

RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}[${MULTILIB_USEDEP}]
	app-office/linuxbuh-1c-installer[${MULTILIB_USEDEP}]
	=app-office/1c-enterprise83-server-${PV}:${SLOT}[${MULTILIB_USEDEP}]
	>=dev-libs/icu-4.6[${MULTILIB_USEDEP}]
	net-libs/webkit-gtk-linuxbuh-bin:3[${MULTILIB_USEDEP}]
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
    einfo "Внимание! Установите программу"
    einfo "app-office/linuxbuh-1c-installer"
    einfo "Скачайте дистрибутив платформы с помощью программы linuxbuh-1c-installer и установите."
}


src_install() {
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/usr" "${D}" || die "install failed!"

}
