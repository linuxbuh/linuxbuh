# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7
inherit rpm

DESCRIPTION="Установка плагина для работы с порталом государственных услуг"
HOMEPAGE="https://ds-plugin.gosuslugi.ru/plugin/upload/Index.spr"
SRC_URI="https://ds-plugin.gosuslugi.ru/plugin/upload/assets/distrib/IFCPlugin-x86_64.rpm"
#SRC_URI="linux-amd64.tgz"
#SRC_URI="$DOWNLOADPAGE/${P}.tgz"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"
RESTRICT="mirror strip"

src_unpack () {
    unpack ${A}
	cd ${WORKDIR}
#	mv cades_linux_amd64/* ${DISTDIR}
#	rm -rf *
	mkdir ${S}
	cd ${S}
#    SUFF="-64-${PV}-1.amd64.rpm"


	rpm_unpack IFCPlugin-x86_64.rpm

}

src_install() {
    cp -vR ${S}/* ${D}/
}

#pkg_postinst() {
#для chromium
#ln -s /usr/share/chromium-browser/extensions /usr/lib64/chromium/extensions
#ln -s /usr/share/chromium-browser/extensions /usr/lib64/chromium-browser/extensions
#для Firefox
#cp /opt/cprocsp/lib/amd64/libnpcades.so.2.0.0 /usr/lib64/browser-plugins/libnpcades.so
#}
