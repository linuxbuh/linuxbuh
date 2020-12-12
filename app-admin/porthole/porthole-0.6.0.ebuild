# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-portage/porthole/porthole-0.6.0.ebuild,v 1.1 2009/10/27 14:25:48 idl0r Exp $

EAPI="7"

PYTHON_COMPAT=( python3_{6,7,8} pypy3  )
inherit distutils-r1

DESCRIPTION="A GTK+-based frontend to Portage"
HOMEPAGE="http://porthole.sourceforge.net"
SRC_URI="mirror://sourceforge/porthole/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc ~sparc ~x86 ~x86-fbsd"
IUSE="nls"

RDEPEND=">=dev-lang/python-2.4[xml,threads]
	>=sys-apps/portage-2.1
	>=dev-python/pygtk-2.4.0
	>=gnome-base/libglade-2.5.0
	nls? ( virtual/libintl )"
DEPEND="${RDEPEND}
	nls? ( >=sys-devel/gettext-0.14 )"

src_install() {
	distutils-r1_pythom_install

	dodoc TODO README NEWS AUTHORS

	keepdir /var/log/porthole
	fperms g+w /var/log/porthole
	keepdir /var/db/porthole
	fperms g+w /var/db/porthole

	# Compile localizations if necessary
	if use nls ; then
		cd "${D}/usr/share/${PN}"
		./pocompile.sh || die "pocompile.sh failed"
	else
		rm -rf "${D}/usr/share/${PN}/i18n"
	fi

	rm -rf "${D}/usr/share/${PN}"/{pocompile,dopot}.sh
}

pkg_preinst() {
	chgrp portage "${D}"/var/log/porthole
	chgrp portage "${D}"/var/db/porthole
}

pkg_postinst() {
	einfo
	einfo "Porthole has updated the way that the upgrades are sent to emerge."
	einfo "In this new way the user needs to set any 'Settings' menu emerge options"
	einfo "Porthole automatically adds '--oneshot' for all upgrades selections"
	einfo "Other options recommended are '--noreplace'  along with '--update'"
	einfo "They allow for portage to skip any packages that might have already"
	einfo "been upgraded as a dependency of another previously upgraded package"
	einfo
}
