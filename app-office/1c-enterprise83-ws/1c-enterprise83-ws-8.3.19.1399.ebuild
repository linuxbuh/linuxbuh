# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

inherit eutils unpacker

DESCRIPTION="WEB Сервер 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_PV="$(ver_rs 3 '-' )"
MY_PN="1c-enterprise-${PV}"
SRC_URI="abi_x86_64? ( ${MY_PN}-ws_${MY_PV}_amd64.tar.gz )"

LICENSE="1CEnterprise_en"
KEYWORDS="amd64"
RESTRICT="fetch"

SLOT="0"

IUSE="nls"

RDEPEND="=app-office/1c-enterprise83-server-${PV}:${SLOT}
	nls? ( =app-office/1c-enterprise83-client-nls-${PV}:${SLOT} )"
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

pkg_postinst() {
	elog "You need to configure fonts for the web compoment of 1C ERP system by exec"
	if use x86 ; then
	    elog "/opt/1C/v83/i386/utils/config_server /usr/share/fonts/corefont"
	elif use amd64 ; then
	    elog "/opt/1C/v83/x86_64/utils/config_server /usr/share/fonts/corefont"
	fi
	elog "or you may get an error \"Failed to initialize graphics subsystem!\""
}
