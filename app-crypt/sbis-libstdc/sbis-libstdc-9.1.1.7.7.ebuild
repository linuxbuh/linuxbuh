# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=7
inherit font gnome2-utils eutils multilib unpacker

DESCRIPTION="Библиотека СБИС stdc++"
HOMEPAGE="https://sbis.ru/"

KEYWORDS="amd64"

#SRC_URI="amd64? ( https://update-msk1.sbis.ru/Sbis3Plugin/rc/linux/deb_repo/sbis-libstdc++.deb -> sbis-libstdc-0.1.deb )"
#if [[ ${PV} != 9999 ]]; then
SRC_URI="amd64? ( https://update-msk1.sbis.ru/Sbis3Plugin/rc/linux/deb_repo/sbis-libstdc++.deb -> ${P}.deb )"
#fi

SLOT="0"
RESTRICT="strip mirror"
LICENSE="GPL-3"
IUSE=""


NATIVE_DEPEND="sys-libs/glibc
	sys-devel/gcc
 "

RDEPEND="
    ${NATIVE_DEPEND}
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {

	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/usr" "${D}" || die "install failed!"
}
