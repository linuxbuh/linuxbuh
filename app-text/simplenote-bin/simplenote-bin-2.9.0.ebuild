# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit eutils unpacker

DESCRIPTION="The simplest way to keep notes"
HOMEPAGE="https://github.com/Automattic/simplenote-electron"
SRC_URI="https://github.com/Automattic/simplenote-electron/releases/download/v2.9.0/Simplenote-linux-2.9.0-amd64.deb"

LICENSE="GPL2"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

DEPEND="dev-libs/nss
	media-libs/alsa-lib
	x11-libs/gtk+:2
	x11-libs/libXtst
	x11-libs/libnotify"
RDEPEND="${DEPEND}"

RESTRICT="mirror"

S="${WORKDIR}"

src_unpack() {
	unpack_deb ${A}
}

src_install() {
	mv * "${D}" || die
}
