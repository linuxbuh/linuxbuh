# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=6

inherit eutils

DESCRIPTION="1C:Проедприятие 8.3, Управление торговлей редакции 11 БАЗОВАЯ, файл демонстрационной базы"
HOMEPAGE="http://1c.ru"
SRC_URI="ftp://ftp.linuxbuh.ru/buhsoft/1C/1c83/Conf/trade-base/${P}.tar.gz"

LICENSE="1CEnterprise_en"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror"

RDEPEND=""

#pkg_nofetch() {
#    einfo "Please download"
#    einfo "  - ${P}.tar.gz"
#    einfo "from ${HOMEPAGE} and place them in your DISTDIR directory."
#    wget -P /var/calculate/remote/distfiles $SRC_URI
#}

#src_unpack() {
#	mv /tmp/${P}.tar.gz /var/calculate/remote/distfiles
#	unpack ${A}
#}


src_install() {

cd ${WORKDIR}
mkdir -p ${D}/opt/1C/${PN}
cp -r ${WORKDIR}/${P}/* ${D}/opt/1C/${PN}
}

