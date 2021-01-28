# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
inherit rpm

DESCRIPTION="Cryptopro package"
HOMEPAGE="http://www.cryptopro.ru"
SRC_URI="linux-amd64.tgz"

LICENSE="Cryptopro"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"
RESTRICT="fetch strip"

src_unpack () {
    unpack ${A}
	cd ${WORKDIR}
	mv linux-amd64/* ${DISTDIR}
	rm -rf *
	mkdir ${S}
	cd ${S}
    SUFF="-64-${PV}-5.x86_64.rpm"
    rpm_unpack lsb-cprocsp-base-5.0.11455-5.noarch.rpm
    rpm_unpack lsb-cprocsp-rdr${SUFF}
	rpm_unpack lsb-cprocsp-capilite${SUFF} 
	rpm_unpack lsb-cprocsp-kc1${SUFF} 
	rpm_unpack lsb-cprocsp-pkcs11${SUFF} 
	rpm_unpack cprocsp-rdr-pcsc${SUFF} 
	rpm_unpack cprocsp-rdr-gui-gtk${SUFF}
	rpm_unpack cprocsp-stunnel${SUFF}
	rpm_unpack cprocsp-rdr-rutoken${SUFF}
}

src_install() {
    cp -vR ${S}/* ${D}/
}

#pkg_config() {
#	certmgr -inst -file ${DISTDIR}/uec.cer -store=Root
#	certmgr -inst -file ${DISTDIR}/uec2.cer -store=Root
#	/opt/cprocsp/sbin/amd64/configure_base_prov.sh kc1
#}
