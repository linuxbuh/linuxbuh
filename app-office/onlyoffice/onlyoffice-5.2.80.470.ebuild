# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit fdo-mime font gnome2-utils eutils multilib unpacker

DESCRIPTION="Офисный пакет OnlyOffice - замена Microsoft Office"
HOMEPAGE="http://www.onlyoffice.com/"

KEYWORDS="amd64"

SRC_URI="amd64? ( ftp://ftp.linuxbuh.ru/linuxbuh/app-office/onlyoffice/onlyoffice-${PV}.tar.gz )"

SLOT="0"
RESTRICT="strip mirror"
LICENSE="AGPL-3"
IUSE=""


NATIVE_DEPEND="
"
RDEPEND="
    ${NATIVE_DEPEND}
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {

mkdir -p ${D}/opt/onlyoffice
mkdir -p ${D}/usr/share/applications
mkdir -p ${D}/usr/share/pixmaps
mkdir -p ${D}/usr/sbin

cp -r ${WORKDIR}/${P}/DesktopEditors-x86_64.AppImage ${D}/opt/onlyoffice
cp -r ${FILESDIR}/desktopeditors.desktop ${D}/usr/share/applications/desktopeditors.desktop
cp -r ${FILESDIR}/onlyoffice.sh ${D}/usr/sbin/onlyoffice.sh
cp -r ${FILESDIR}/*.png ${D}/usr/share/pixmaps


}

pkg_postinst() {

chmod 0755 /opt/onlyoffice/DesktopEditors-x86_64.AppImage
chmod 0755 /usr/sbin/onlyoffice.sh

}