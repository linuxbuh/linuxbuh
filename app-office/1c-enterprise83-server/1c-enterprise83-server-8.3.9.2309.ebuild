# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

inherit unpacker

DESCRIPTION="Сервер 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_PV="$(ver_rs 3 '-' )"
MY_PN="1c-enterprise83-server"
SRC_URI="abi_x86_64? ( ${MY_PN}_${MY_PV}_amd64.tar.gz )"

LICENSE="1CEnterprise_en"
KEYWORDS="amd64"
RESTRICT="fetch"

SLOT="0"
IUSE="nls postgres fontconfig server -hasp -hasp-emul"

RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}
	app-office/linuxbuh-1c-installer
	postgres? ( dev-db/postgresql-1c-pro[pg_legacytimestamp] )
	server? ( app-office/1c-server-utils )
	hasp? ( sys-apps/hasp )
	hasp-emul? ( app-emulation/usbhasp )
		fontconfig? ( gnome-extra/libgsf
			app-text/ttf2pt1
			media-gfx/imagemagick[corefonts]
			dev-db/unixODBC )
	dev-db/unixODBC"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

pkg_nofetch() {
    einfo "Внимание !!!"
    einfo "Установите пакет linuxbuh-1c-installer"
    einfo "Скачайте дистрибутив платформы 1С:Предприятие 8.3 с помощью программы linuxbuh-1c-get-platform-server-gentoo и установите."
}

src_install() {
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"

}
