# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=7
inherit fdo-mime font gnome2-utils eutils multilib unpacker

DESCRIPTION="Локализация интерфейса WPS Office"
HOMEPAGE="https://github.com/wps-community/wps_i18n"

KEYWORDS="amd64"

#SRC_URI="amd64? ( https://github.com/wps-community/wps_i18n/archive/master.zip )"

SLOT="0"
RESTRICT="strip mirror"
LICENSE="GPL"
IUSE="ru"


RDEPEND="app-office/wps-office
	dev-qt/qtcore
	dev-qt/linguist
"
DEPEND="${RDEPEND}"

S="${WORKDIR}"

pkg_postinst(){

mkdir /tmp/wps-office-i18n
git clone https://github.com/wps-community/wps_i18n.git /tmp/wps-office-i18n
cd /tmp/wps-office-i18n/ru_RU/
make install
#rm -r /tmp/wps-office-i18n

}
