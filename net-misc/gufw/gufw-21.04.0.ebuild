# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

PYTHON_COMPAT=( python3_{8,9} )

DISTUTILS_IN_SOURCE_BUILD=1

inherit distutils-r1

DESCRIPTION="GUI frontend for managing ufw."
HOMEPAGE="https://gufw.org/ https://costales.github.io/projects/gufw/"
SRC_URI="https://github.com/costales/gufw/archive/${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="dev-python/python-distutils-extra"
RDEPEND="net-firewall/ufw
    x11-libs/gtk+:3[introspection]
    net-libs/webkit-gtk[introspection]
    dev-python/netifaces
    sys-auth/polkit
    x11-themes/gnome-icon-theme-symbolic
    dev-python/pygobject:3
    sys-auth/elogind
    dev-util/intltool
"
S=${WORKDIR}/${PN}-${PV}


pkg_postinst() {
    local PYTHONVERSION="$(python -c 'import sys; print("{}.{}".format(sys.version_info.major, sys.version_info.minor))')"
    sed -E "s|share/gufw|lib/python${PYTHONVERSION}/site-packages|g" -i /usr/bin/gufw-pkexec
}
