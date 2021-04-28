# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="GPRename is a complete batch renamer for files and directories"
HOMEPAGE="http://gprename.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
#IUSE="nautilus-actions"

RDEPEND="
	dev-lang/perl
	sys-devel/gettext
	dev-perl/Gtk3
	dev-perl/glib-perl
	dev-perl/Locale-gettext
	dev-perl/libintl-perl
"
DEPEND="${RDEPEND}"
#	nautilus-actions? ( gnome-extra/nautilus-actions )"

src_prepare() {
		#Set /usr rather than /usr/local
		sed -i -e 's:/usr/local:/usr:g' Makefile || die "Installation failed with sed!"
		#Things get hairy when install calls uninstall
		sed -i -e 's:install\: uninstall:install\::g' Makefile || die "Installation failed with sed!"
		#Take over file installations
		sed  '/\sinstall\s-/,+3d' Makefile > Makefile.tmp || die "Installation failed with sed:"
		mv Makefile.tmp Makefile
		mkdir -p build/locale || die
}

src_configure() {
	einfo "No configure needed"
}

src_install() {
		#Make install fails miserably, so our edited makefile just compiles .po to .mo,
		#and then we do all the installtion here
		emake install DESTDIR="${D}" || die "emake install failed"
		domo build/locale/*.mo
		doman man/gprename.1
		insinto /usr/share/icons
		doins icon/gprename.png
		dobin bin/gprename
		insinto /usr/share/applications/
		doins bin/gprename.desktop
#		use nautilus-actions && doins gprename-nautilus-actions.xml
}
