# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=6

inherit eutils

DESCRIPTION="1C:Проедприятие 8.3, Управление торговлей редакции 11 ПРОФ, файлы обновления конфигурации"
HOMEPAGE="http://1c.ru"
SRC_URI="ftp://ftp.linuxbuh.ru/buhsoft/1C/1c83/Conf/trade/${P}.tar.gz"

LICENSE="1CEnterprise_en"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror strip"

RDEPEND=""



src_install() {
cd ${WORKDIR}
mkdir -p ${D}/opt/1C/${PN}
cp -r ${WORKDIR}/${P}/* ${D}/opt/1C/${PN}
}

