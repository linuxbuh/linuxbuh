# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="Хранилище конфигураций 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_PV="$(replace_version_separator 3 '-' )"
MY_PN="1c-enterprise83-crs"
SRC_URI="abi_x86_32? ( ${MY_PN}_${MY_PV}_i386.tar.gz )"

LICENSE="1CEnterprise_en"
KEYWORDS="amd64 x86"
RESTRICT="fetch"


SLOT="0"


RDEPEND="=app-office/1c-enterprise83-common-${PV}:${SLOT}[${MULTILIB_USEDEP}]
	=app-office/1c-enterprise83-server-${PV}:${SLOT}[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

pkg_nofetch() {
    einfo "Внимание !!!"
    einfo "Установите пакет linuxbuh-1c-installer"
    einfo "Скачайте дистрибутив платформы 1С:Предприятие 8.3 с помощью программы linuxbuh-1c-get-platform-server-gentoo и установите."
}


src_install() {
	dodir /opt
	mv "${WORKDIR}"/opt/* "${D}"/opt
}