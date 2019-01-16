# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit fdo-mime font gnome2-utils eutils multilib unpacker

DESCRIPTION="sputnik webrowser"
HOMEPAGE="https://browser.sputnik.ru/"

KEYWORDS="~amd64"

SRC_URI="
    amd64? ( http://download.sputnik.ru/browser/ubuntu_sputnik-browser-stable_amd64.deb )
    "

SLOT="0"
RESTRICT="strip mirror"
LICENSE="AGPL-3"
IUSE=""


NATIVE_DEPEND="gnome-base/gconf
"
RDEPEND="
    ${NATIVE_DEPEND}
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_unpack(){
        unpack_deb ${A}
}

src_install() {
	cp -R "${WORKDIR}/etc" "${D}" || die "install failed!" 
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!" 
	cp -R "${WORKDIR}/usr" "${D}" || die "install failed!" 
}

