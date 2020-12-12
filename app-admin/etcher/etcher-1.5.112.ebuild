# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit fdo-mime font gnome2-utils eutils multilib unpacker

DESCRIPTION="Flash OS images to SD cards & USB drives, safely and easily."
HOMEPAGE="https://www.balena.io/etcher//"

KEYWORDS="amd64"

SRC_URI="amd64? ( https://github.com/balena-io/etcher/releases/download/v1.5.112/balena-etcher-electron-1.5.112-linux-x64.zip )
    "

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

mkdir -p ${D}/opt/etcher
mkdir -p ${D}/usr/share/applications
mkdir -p ${D}/usr/share/pixmaps

cp -r ${WORKDIR}/* ${D}/opt/etcher
cp -r ${FILESDIR}/etcher.desktop ${D}/usr/share/applications/etcher.desktop
cp -r ${FILESDIR}/*.svg ${D}/usr/share/pixmaps


}

pkg_postinst() {

chmod 0755 /opt/etcher/*.AppImage

echo "#!/bin/bash

MACHINE_TYPE=`uname -m`
if [ \$MACHINE_TYPE == x86_64 ]; then
/opt/etcher/balenaEtcher-${PV}-x64.AppImage
fi
if [ \$MACHINE_TYPE == 32 ]; then
/opt/etcher/balenaEtcher-${PV}-ai32.AppImage
fi" > /usr/sbin/etcher

chmod 0755 /usr/sbin/etcher

}