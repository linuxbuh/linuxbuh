# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7
inherit rpm

DESCRIPTION="Cades plugin package"
HOMEPAGE="http://www.cryptopro.ru"
SRC_URI="https://www.cryptopro.ru/sites/default/files/products/cades/current_release_2_0/cades-linux-amd64.tar.gz"
#SRC_URI="https://ftp.linuxbuh.ru/linuxbuh/www-plugins/cades/cades-linux-amd64.tar.gz"
#SRC_URI="linux-amd64.tgz"
#SRC_URI="$DOWNLOADPAGE/${P}.tgz"

LICENSE="Cryptopro"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="app-crypt/cryptoprocsp"
RDEPEND="${DEPEND}"
RESTRICT="mirror strip"

src_unpack () {
    unpack ${A}
	cd ${WORKDIR}
	mv * ${DISTDIR}
	rm -rf *
	mkdir ${S}
	cd ${S}
    SUFF="-64-${PV}-1.amd64.rpm"


	rpm_unpack cprocsp-pki-cades${SUFF}
	rpm_unpack cprocsp-pki-phpcades${SUFF}
	rpm_unpack cprocsp-pki-plugin${SUFF}

}

src_install() {
    cp -vR ${S}/* ${D}/
}

pkg_postinst() {
#для chromium
#ln -s /usr/share/chromium-browser/extensions /usr/lib64/chromium/extensions
ln -s /usr/share/chromium-browser/extensions /usr/lib64/chromium-browser/extensions
#для Firefox
#cp /opt/cprocsp/lib/amd64/libnpcades.so.2.0.0 /usr/lib64/browser-plugins/libnpcades.so
}
