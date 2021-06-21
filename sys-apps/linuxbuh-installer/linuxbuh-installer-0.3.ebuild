# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=7

inherit eutils

DESCRIPTION="Linuxbuh Installer"
HOMEPAGE="http://linuxbuh.ru"
SRC_URI="ftp://ftp.linuxbuh.ru/linuxbuh/sys-apps/linuxbuh-installer/${P}.tar.gz"

LICENSE="GPL"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RESTRICT="mirror strip"

RDEPEND="x11-terms/xterm
	x11-misc/xdialog
	app-admin/sudo
	net-misc/wput"


src_install() {
cd ${WORKDIR}
mkdir -p ${D}/usr/share/linuxbuh-installer
mkdir -p ${D}/usr/share/linuxbuh-installer/txt
mkdir -p ${D}/usr/share/applications
mkdir -p ${D}/usr/share/pixmaps
mkdir -p ${D}/usr/bin

cp -r ${FILESDIR}/lb-update.desktop ${D}/usr/share/applications/lb-update.desktop
cp -r ${FILESDIR}/lb-overlay-update.desktop ${D}/usr/share/applications/lb-overlay-update.desktop
cp -r ${FILESDIR}/linuxbuh-installer.desktop ${D}/usr/share/applications/linuxbuh-installer.desktop
cp -r ${FILESDIR}/linuxbuh-installer-update.desktop ${D}/usr/share/applications/linuxbuh-installer-update.desktop
cp -r ${FILESDIR}/linuxbuh-installer.png ${D}/usr/share/pixmaps
cp -r ${WORKDIR}/${P}/linuxbuh-installer ${D}/usr/bin
cp -r ${WORKDIR}/${P}/linuxbuh-installer-update ${D}/usr/bin
cp -r ${WORKDIR}/${P}/lb-overlay-update ${D}/usr/bin
cp -r ${WORKDIR}/${P}/lb-update ${D}/usr/bin
cp -r ${WORKDIR}/${P}/wgetlinuxbuh ${D}/usr/bin
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