
# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit unpacker eutils

DESCRIPTION="A simple & beautiful desktop client for WhatsApp Web"
HOMEPAGE="https://whatsie.chat/"

SRC_URI_AMD64="https://github.com/Aluxian/Whatsie/releases/download/v${PV}/whatsie-${PV}-linux-amd64.deb"
SRC_URI_X86="https://github.com/Aluxian/Whatsie/releases/download/v$PV/whatsie-${PV}-linux-i386.deb"
SRC_URI="
        amd64? ( ${SRC_URI_AMD64} )
        x86? ( ${SRC_URI_X86} )
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="autostart"


S="${WORKDIR}"

RESTRICT="mirror"

src_unpack() {
    unpack_deb ${A}
}

src_install() {
    if use autostart ; then
      cp -R "${WORKDIR}/etc" "${D}" || die "install failed!"
    fi

    cp -R "${WORKDIR}/usr" "${D}" || die "install failed!"
    cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"

}

