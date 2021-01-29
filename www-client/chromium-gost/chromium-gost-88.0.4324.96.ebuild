# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=7
inherit font gnome2-utils eutils multilib unpacker

DESCRIPTION="Chromium с поддержкой ГОСТ"
HOMEPAGE="https://github.com/deemru/chromium-gost"

KEYWORDS="amd64"

SRC_URI="amd64? ( https://github.com/deemru/chromium-gost/releases/download/88.0.4324.96/chromium-gost-88.0.4324.96-linux-amd64.deb )"

SLOT="0"
RESTRICT="strip mirror"
LICENSE="GPL-3"
IUSE=""


NATIVE_DEPEND=""

RDEPEND="
    ${NATIVE_DEPEND}
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {

	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/usr" "${D}" || die "install failed!"

}
