# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit fdo-mime font gnome2-utils eutils multilib unpacker

DESCRIPTION="Офисный пакет OnlyOffice - замена Microsoft Office"
HOMEPAGE="http://www.onlyoffice.com/"

KEYWORDS="amd64"

SRC_URI="amd64? ( https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb )"

SLOT="0"
RESTRICT="strip mirror"
LICENSE="AGPL-3"
IUSE=""


NATIVE_DEPEND=""

RDEPEND="
    ${NATIVE_DEPEND}
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {

	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/usr" "${D}" || die "install failed!"

}
