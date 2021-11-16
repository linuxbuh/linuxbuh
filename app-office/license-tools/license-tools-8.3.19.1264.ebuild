# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

inherit eutils unpacker

DESCRIPTION="Установщик лицензий 1C:Проедприятие 8.3 для GNU/LINUX"
HOMEPAGE="http://v8.1c.ru"

MY_P="license-tools-${PV}"
SRC_URI=" ${MY_P}.tar.gz "

LICENSE="1CEnterprise_en"
KEYWORDS="amd64"
RESTRICT="fetch"

SLOT="0"

IUSE=""

RDEPEND="dev-java/openjdk-jre-bin"
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
mkdir -p ${D}/opt/1C/license-tools/${PV}
cp -r ${WORKDIR}/${P}/* ${D}/opt/1C/license-tools/${PV}
}

pkg_postinst() {

chmod 0755 /opt/1C/license-tools/${PV}/1ce-installer
chmod 0755 /opt/1C/license-tools/${PV}/1ce-installer-cli
    einfo "Внимание !!!"
    einfo "Запуск установщика лицензий 1С"
    einfo "CLI (консольный) /opt/1C/license-tools/${PV}/1ce-installer-cli"
    einfo "GUI (графический) /opt/1C/license-tools/${PV}/1ce-installer"

}
