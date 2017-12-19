# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=3

inherit eutils

DESCRIPTION="Linuxbuh Installer"
HOMEPAGE="http://linuxbuh.ru"
SRC_URI="https://github.com/downloads/zaharchuktv/linuxbuh/${P}.tar.gz"


LICENSE="GPL"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RESTRICT="mirror strip"

RDEPEND="x11-terms/xterm
	x11-misc/xdialog
	app-admin/sudo"


src_unpack() {
	    unpack ${A}
	    
}

src_install() {
cd ${WORKDIR}
mkdir -p ${D}/usr/share/linuxbuh-installer
mkdir -p ${D}/usr/share/linuxbuh-installer/txt
mkdir -p ${D}/usr/share/applications
mkdir -p ${D}/usr/share/pixmaps
mkdir -p ${D}/usr/bin

cp -r ${WORKDIR}/${P}/linuxbuh-installer.desktop ${D}/usr/share/applications/linuxbuh-installer.desktop
cp -r ${WORKDIR}/${P}/linuxbuh-installer-update.desktop ${D}/usr/share/applications/linuxbuh-installer-update.desktop
cp -r ${WORKDIR}/${P}/linuxbuh-installer.png ${D}/usr/share/pixmaps
cp -r ${WORKDIR}/${P}/linuxbuh-installer-update ${D}/usr/bin
cp -r ${WORKDIR}/${P}/linuxbuh-installer ${D}/usr/bin
cp -r ${WORKDIR}/${P}/wgetnarodru ${D}/usr/bin
cp -r ${WORKDIR}/${P}/txt ${D}/usr/share/linuxbuh-installer

}


pkg_postinst() {

nopasswd=`ls /etc/sudoers.d/ | grep nopasswd`

if [ nopasswd == $nopasswd ]; then
    echo "Файл nopasswd есть в каталоге"
    else
    touch /etc/sudoers.d/nopasswd
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/nopasswd
    echo "Файл nopasswd нет в каталоге"
    fi

}