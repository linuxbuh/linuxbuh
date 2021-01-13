
# Copyright 2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit desktop unpacker xdg

DESCRIPTION="A cross-platform, complete password management solution."
HOMEPAGE="https://www.enpass.io"
SRC_URI="https://apt.enpass.io/pool/main/e/${PN}/${PN}_${PV}_amd64.deb"

LICENSE="SINEW-EULA"
SLOT="0"
KEYWORDS="~amd64"

# use flags
IUSE="pulseaudio"

# Distribution is restricted by the legal notice
RESRICT="mirror"

DEPEND=""
RDEPEND="
    sys-process/lsof
    dev-libs/glib:2
    media-libs/fontconfig
    media-libs/freetype:2
    media-libs/mesa
    pulseaudio? ( media-sound/pulseaudio )
    !pulseaudio? ( media-sound/apulse )
    net-misc/curl
    net-print/cups
    sys-apps/dbus
    sys-apps/util-linux
    sys-libs/zlib
    x11-libs/gtk+:3
    x11-libs/libICE
    x11-libs/libSM
    x11-libs/libX11
    x11-libs/libxcb
    x11-libs/libXi
    x11-libs/libXrender
    x11-libs/libXScrnSaver
    x11-libs/pango"
BDEPEND=""

PATCHES=(
    "${FILESDIR}/enpass-desktopfile.patch"
)

S="${WORKDIR}"

src_install() {
    insinto /opt/enpass
    doins -r opt/enpass/.
    fperms +x /opt/enpass/Enpass
    fperms +x /opt/enpass/importer_enpass

    dodir /usr/bin
    cat <<-EOF >"${D}"/usr/bin/enpass || die
#! /bin/sh
LD_LIBRARY_PATH="/usr/$(get_libdir)/apulse" \\
exec /opt/enpass/Enpass "\$@"
EOF

    fperms +x /usr/bin/enpass

    insinto /usr/share/mime/packages
    doins usr/share/mime/packages/application-enpass.xml

    domenu usr/share/applications/enpass.desktop

    gzip -d usr/share/doc/enpass/changelog.gz
    dodoc usr/share/doc/enpass/changelog

    local size

    for size in 16 22 24 32 48 ; do
        doicon -c status -s ${size} usr/share/icons/hicolor/${size}x${size}/status/enpass-status.png
        doicon -c status -s ${size} usr/share/icons/hicolor/${size}x${size}/status/enpass-status-dark.png
    done

    for size in 16 24 32 48 64 96 128 256; do
        doicon -s ${size} usr/share/icons/hicolor/${size}x${size}/apps/enpass.png
    done
}
