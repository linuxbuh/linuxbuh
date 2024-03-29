# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

DESCRIPTION="In-place conversion of text typed in with a wrong keyboard layout"
HOMEPAGE="http://www.xneur.ru/"
SRC_URI="https://github.com/linuxbuh/xneur/archive/refs/tags/0.21.0.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="aplay debug gstreamer gtk gtk3 keylogger libnotify nls openal xosd +spell"

COMMON_DEPEND=">=dev-libs/libpcre-5.0
	sys-libs/zlib
	>=x11-libs/libX11-1.1
	x11-libs/libXi
	x11-libs/libXtst
	app-dicts/aspell-ru
	gstreamer? ( media-libs/gstreamer:1.0 )
	!gstreamer? (
		openal? ( >=media-libs/freealut-1.0.1 )
		!openal? (
			aplay? ( >=media-sound/alsa-utils-1.0.17 ) ) )
	libnotify? (
		gtk? (
			gtk3? ( x11-libs/gtk+:3 )
			!gtk3? ( x11-libs/gtk+:2 ) )
		>=x11-libs/libnotify-0.4.0 )
	spell? ( app-text/enchant )
	xosd? ( x11-libs/xosd )"
RDEPEND="${COMMON_DEPEND}
	gstreamer? ( media-libs/gst-plugins-good
		media-plugins/gst-plugins-meta )
	nls? ( virtual/libintl )
	gtk3? ( !x11-misc/gxneur )"
DEPEND="${COMMON_DEPEND}
	dev-util/intltool
	virtual/pkgconfig
	nls? ( sys-devel/gettext )"

REQUIRED_USE="libnotify? ( gtk )"

src_prepare() {
	default

	autogen.sh
	eautoreconf
}

src_configure() {
	local myconf

	if use gstreamer; then
		elog "Using gstreamer for sound output."
		myconf="--with-sound=gstreamer"
	elif use openal; then
		elog "Using openal for sound output."
		myconf="--with-sound=openal"
	elif use aplay; then
		elog "Using aplay for sound output."
		myconf="--with-sound=aplay"
	else
		elog "Sound support disabled."
		myconf="--with-sound=no"
	fi

	if use gtk; then
		if use gtk3; then
			myconf="${myconf} --with-gtk=gtk3"
		else
			myconf="${myconf} --with-gtk=gtk2"
		fi
	else
		myconf="${myconf} --without-gtk"
	fi

	econf ${myconf} \
		$(use_with debug) \
		$(use_enable nls) \
		$(use_with spell) \
		$(use_with xosd) \
		$(use_with libnotify) \
		$(use_with keylogger)
}

pkg_postinst() {
	elog "This is command line tool. If you are looking for GUI frontend just"
	elog "emerge gxneur or kdexneur, which uses xneur transparently as backend."

	elog
	elog "It is recommended to install dictionary for your language"
	elog "(myspell or aspell), for example app-dicts/aspell-ru."

	ewarn
	ewarn "Note: if xneur became slow, try to comment out AddBind options in config file."
}
