# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="Сервер 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-server"
SRC_URI="abi_x86_32? ( ${MY_PN}_${MY_PV}_i386.tar.gz )
	abi_x86_64? ( ${MY_PN}_${MY_PV}_amd64.tar.gz )"

LICENSE="1CEnterprise_en"
KEYWORDS="amd64 x86"
RESTRICT="fetch"

SLOT="0"
IUSE="nls postgres fontconfig server"

RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}[${MULTILIB_USEDEP}]
	app-office/linuxbuh-1c-installer[${MULTILIB_USEDEP}]
	postgres? ( dev-db/postgresql-1c-pro[pg_legacytimestamp,${MULTILIB_USEDEP}] )
	server? ( app-office/1c-server-utils[${MULTILIB_USEDEP}] )
	fontconfig? ( gnome-extra/libgsf[${MULTILIB_USEDEP}]
			app-text/ttf2pt1[${MULTILIB_USEDEP}]
			media-gfx/imagemagick[corefonts,${MULTILIB_USEDEP}]
			dev-db/unixODBC[${MULTILIB_USEDEP}] )
	dev-db/unixODBC[${MULTILIB_USEDEP}]"
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

}
