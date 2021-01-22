# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit eutils

DESCRIPTION="Joplin is a free, open source note taking and to-do application, which can handle a large number of notes organised into notebooks. The notes are searchable, can be copied, tagged and modified either from the applications directly or from your own text editor."
HOMEPAGE="https://https://joplinapp.org//"

KEYWORDS="amd64"

SRC_URI="amd64? ( https://github.com/laurent22/joplin/releases/download/v${PV}/Joplin-${PV}.AppImage )
    "

SLOT="0"
RESTRICT="mirror strip"
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

cd ${WORKDIR}
mkdir -p ${D}/opt/Joplin
mkdir -p ${D}/usr/share/applications
mkdir -p ${D}/usr/share/pixmaps

cp -r /var/calculate/remote/distfiles/Joplin-${PV}.AppImage ${D}/opt/Joplin/Joplin.AppImage
cp -r ${FILESDIR}/*.desktop ${D}/usr/share/applications/*.desktop
cp -r ${FILESDIR}/*.png ${D}/usr/share/pixmaps


}

pkg_postinst() {

chmod 0755 /opt/Joplin/*.AppImage

echo "#!/bin/bash
/opt/Joplin/Joplin.AppImage
" > /usr/sbin/joplin-desktop-bin

chmod 0755 /usr/sbin/joplin-desktop-bin


}
