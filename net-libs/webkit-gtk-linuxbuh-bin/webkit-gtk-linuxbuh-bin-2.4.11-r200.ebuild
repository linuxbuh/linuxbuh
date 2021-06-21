# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=7

inherit eutils versionator unpacker


DESCRIPTION="Бинарный пакет ${P} для платформы 1С:Предприятие 8.3"
HOMEPAGE="http://linuxbuh.ru"

DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/linuxbuh/net-libs/webkit-gtk-linuxbuh-bin"

SRC_URI_AMD64="$DOWNLOADPAGE/webkit-gtk-linuxbuh-bin-2.4.11-r200.amd64.tar.gz"

SRC_URI="
	amd64? ( ${SRC_URI_AMD64} )
"


LICENSE="GPL"
SLOT="2"
KEYWORDS="amd64"

RESTRICT="mirror strip"

IUSE="test aqua coverage debug +egl +geoloc gles2 gnome-keyring +gstreamer +introspection +jit +opengl spell +webgl +X"
# bugs 372493, 416331
REQUIRED_USE="
	geoloc? ( introspection )
	gles2? ( egl )
	introspection? ( gstreamer )
	webgl? ( ^^ ( gles2 opengl ) )
	!webgl? ( ?? ( gles2 opengl ) )
	|| ( aqua X )
"

# use sqlite, svg by default
RDEPEND="
	dev-db/sqlite:3=
	>=dev-libs/glib-2.36:2
	>=dev-libs/icu-3.8.1-r1:=
	>=dev-libs/libxml2-2.6:2
	>=dev-libs/libxslt-1.1.7
	>=media-libs/fontconfig-2.5:1.0
	>=media-libs/freetype-2.4.2:2
	>=media-libs/harfbuzz-0.9.7:=[icu(+)]
	>=media-libs/libpng-1.4:0=
	media-libs/libwebp:=
	>=net-libs/libsoup-2.42:2.4[introspection?]
	virtual/jpeg:0=
	>=x11-libs/cairo-1.10:=[X]
	>=x11-libs/gtk+-2.24.10:2[aqua?,introspection?]
	x11-libs/libXrender
	x11-libs/libXt
	>=x11-libs/pango-1.30.0

	egl? ( media-libs/mesa[egl] )
	geoloc? ( >=app-misc/geoclue-2.1.5:2.0 )
	gles2? ( media-libs/mesa[gles2] )
	gnome-keyring? ( app-crypt/libsecret )
	gstreamer? (
		>=media-libs/gstreamer-1.2:1.0
		>=media-libs/gst-plugins-base-1.2:1.0 )
	introspection? ( >=dev-libs/gobject-introspection-1.32.0:= )
	opengl? ( virtual/opengl )
	spell? ( >=app-text/enchant-0.22:= )
	webgl? (
		x11-libs/cairo[opengl]
		x11-libs/libXcomposite
		x11-libs/libXdamage )
"

# paxctl needed for bug #407085
# Need real bison, not yacc
DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	${RUBY_DEPS}
	>=dev-lang/perl-5.10
	>=dev-libs/atk-2.8.0
	>=dev-util/gtk-doc-am-1.10
	>=dev-util/gperf-3.0.1
	>=sys-devel/bison-2.4.3
	>=sys-devel/flex-2.5.34
	|| ( >=sys-devel/gcc-4.7 >=sys-devel/clang-3.3 )
	sys-devel/gettext
	>=sys-devel/make-3.82-r4
	virtual/pkgconfig

	geoloc? ( dev-util/gdbus-codegen )
	introspection? ( jit? ( sys-apps/paxctl ) )
	test? (
		dev-lang/python:2.7
		dev-python/pygobject:3[python_targets_python2_7]
		x11-themes/hicolor-icon-theme
		jit? ( sys-apps/paxctl ) )
"

src_unpack() {
	mv ${DISTDIR}/webkit-gtk-linuxbuh-bin-2.4.11-r200.${ARCH}.tar.gz ${WORKDIR}/webkit-gtk-linuxbuh-bin-2.4.11.tar.gz || die
	einfo "Unpacking new webkit-gtk-linuxbuh-bin-2.4.11.tar.gz"
	unpack "./webkit-gtk-linuxbuh-bin-2.4.11.tar.gz"
}


src_install() {
cd ${WORKDIR}
mkdir -p ${D}/usr
cp -r ${WORKDIR}/webkit-gtk-linuxbuh-bin-2.4.11/usr/* ${D}/usr
}
