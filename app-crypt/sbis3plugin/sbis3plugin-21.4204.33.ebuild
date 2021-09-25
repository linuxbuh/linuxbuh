# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=7
inherit font gnome2-utils eutils multilib unpacker

DESCRIPTION="СБИС Плагин. Desktop Plugin for convenient work in the browser SBIS3Plugin (SABY Plugin) — a desktop application for working with notifications, editing documents in a browser, entering your personal account by certificate, uploading files to the cloud, and so on"
HOMEPAGE="https://sbis.ru/"

KEYWORDS="amd64"

SRC_URI="amd64? ( https://update-msk1.sbis.ru/Sbis3Plugin/rc/linux/deb_repo/sbis3plugin.deb -> sbis3plugin-${PN}.deb )"

SLOT="0"
RESTRICT="strip mirror"
LICENSE="GPL-3"
IUSE=""


NATIVE_DEPEND="sys-libs/glibc
	sys-devel/gcc
	app-crypt/sbis-libstdc
	dev-libs/atk
	dev-libs/libatomic_ops
	virtual/libc
	virtual/libcrypt
	sys-apps/dbus
	x11-libs/libdrm
	media-libs/gegl
	dev-libs/expat
	media-libs/fontconfig
	app-eselect/eselect-fontconfig
	x11-libs/gdk-pixbuf
	dev-libs/glib
	media-libs/gstreamer
	x11-libs/gtk+:2
	x11-libs/gtk+:3
	media-libs/harfbuzz
	app-arch/lzma
	dev-libs/nspr
	dev-libs/nss
	x11-libs/pango
	sys-apps/pcsc-lite
	media-sound/pulseaudio
	sys-libs/libstdc++-v3
	sys-libs/libudev-compat
	app-misc/ca-certificates
	media-libs/libvorbis
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXinerama
	x11-apps/xrandr
	x11-libs/libXrender
	x11-libs/libXtst
	sys-libs/zlib
 "

RDEPEND="
    ${NATIVE_DEPEND}
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {

	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"
	cp -R "${FILESDIR}/sbis3plugin-postinst.sh" "${D}/opt/sbis3plugin/sbis3plugin-postinst.sh" || die "install failed!"
	cp -R "${FILESDIR}/addDaemonRestart.sh" "${D}/opt/sbis3plugin/temp/${PN}/service/update_scripts/addDaemonRestart.sh" || die "install failed!"
}

pkg_postinst() {

    elog "Запустите скрипт /opt/sbis3plugin/sbis3plugin-postinst.sh"

}