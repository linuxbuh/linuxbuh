# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

inherit eutils unpacker


DESCRIPTION="Пакет Common 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_PV="$(ver_rs 3 '-' )"
MY_PN="1c-enterprise-${PV}"
SRC_URI="abi_x86_64? ( ${MY_PN}-common_${MY_PV}_amd64.tar.gz )"

LICENSE="1CEnterprise_en"
KEYWORDS="amd64"
RESTRICT="fetch"

SLOT="0"

IUSE="nls"

RDEPEND=">=sys-libs/glibc-2.3
	>=dev-libs/icu-3.8.1-r1
	app-office/linuxbuh-1c-installer"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

pkg_nofetch() {
    einfo "Внимание !!!"
    einfo "Установите пакет linuxbuh-1c-installer"
    einfo "Скачайте дистрибутив платформы 1С:Предприятие 8.3 с помощью программы linuxbuh-1c-get-platform-client-gentoo или linuxbuh-1c-get-platform-server-gentoo и установите."
}

src_install() {
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"
}
