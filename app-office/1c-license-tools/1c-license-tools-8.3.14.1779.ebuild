# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="WEB Сервер 1C:Проедприятие 8.3 для GNU\LINUX"
HOMEPAGE="http://v8.1c.ru"

SRC_URI=" ${P}.tar.gz "

LICENSE="1CEnterprise_en"
KEYWORDS="amd64 x86"
RESTRICT="fetch"

SLOT="0"

IUSE=""

RDEPEND="=app-office/1c-enterprise83-client-${PV}:${SLOT}[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

pkg_nofetch() {
    einfo "Внимание !!!"
    einfo "Установите пакет linuxbuh-1c-installer"
    einfo "Скачайте дистрибутив платформы 1С:Предприятие 8.3 с помощью программы linuxbuh-1c-get-platform-client-gentoo или linuxbuh-1c-get-platform-server-gentoo и установите."
}


S="${WORKDIR}"

src_install() {
cd ${WORKDIR}
mkdir -p ${D}/opt/1C/license-tools
cp -r ${WORKDIR}/${P}/* ${D}/opt/1C/license-tools
}

pkg_postinst() {

chmod 0755 /opt/1C/license-tools/1ce-installer
chmod 0755 /opt/1C/license-tools/1ce-installer-cli

}
