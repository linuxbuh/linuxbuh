# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

inherit eutils

DESCRIPTION="Kali Undercover"
HOMEPAGE="https://gitlab.com/kalilinux/packages/kali-undercover"
SRC_URI="http://archive.kali.org/kali/pool/main/k/kali-undercover/kali-undercover_2021.1.2.tar.xz"

LICENSE="GPL"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror strip"

RDEPEND="xfce-extra/xfce4-whiskermenu-plugin"

src_install() {
cd ${WORKDIR}
mkdir -p ${D}/usr/share
mkdir -p ${D}/usr/bin
cp -r ${WORKDIR}/${P}/share/* ${D}/usr
cp -r ${WORKDIR}/${P}/bin/* ${D}/usr/bin
}

pkg_postinst() {
cd /tmp
wget https://github.com/B00merang-Project/Windows-10-Dark/archive/master.zip
unzip master.zip
mv Windows-10-Dark-master /usr/share/themes
}
