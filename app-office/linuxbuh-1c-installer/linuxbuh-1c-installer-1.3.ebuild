# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=7

inherit eutils unpacker

DESCRIPTION="Инсталлятор для платформы и конфигураций 1C:Проедприятие 8.3"
HOMEPAGE="https://linuxbuh.ru"

#DOWNLOADPAGE="https://github.com/linuxbuh/linuxbuh-1c-installer/archive/refs/tags/1.2.tar.gz"

SRC_URI="https://github.com/linuxbuh/linuxbuh-1c-installer/archive/refs/tags/${PV}.tar.gz"

LICENSE="linuxbuh"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RESTRICT="mirror"

RDEPEND="x11-terms/xterm
	x11-misc/xdialog
	app-admin/sudo
	net-misc/wput
	app-arch/deb2targz
	net-misc/curl"


S="${WORKDIR}"

src_install() {
cd ${WORKDIR}
mkdir -p ${D}/usr
mkdir -p ${D}/usr/bin
mkdir -p ${D}/usr/share/applications
mkdir -p ${D}/usr/share/pixmaps
cp -r ${WORKDIR}/${P}/linuxbuh-1c-installer ${D}/usr/bin
cp -r ${WORKDIR}/${P}/linuxbuh-1c-installer-console ${D}/usr/bin
cp -r ${WORKDIR}/${P}/linuxbuh-1c-installer-gui ${D}/usr/bin
cp -r ${WORKDIR}/${P}/linuxbuh-1c-get-platform-client-gentoo ${D}/usr/bin
cp -r ${WORKDIR}/${P}/linuxbuh-1c-get-platform-server-gentoo ${D}/usr/bin
cp -r ${FILESDIR}/linuxbuh-1c-installer.desktop ${D}/usr/share/applications/linuxbuh-1c-installer.desktop
cp -r ${FILESDIR}/linuxbuh-1c-installer.png ${D}/usr/share/pixmaps
}
