# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5
inherit rpm

DESCRIPTION="Cryptopro package"
HOMEPAGE="http://www.cryptopro.ru"
DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/linuxbuh/app-crypt/cryptoprocsp"
#SRC_URI="linux-amd64.tgz"
SRC_URI="$DOWNLOADPAGE/${P}.tgz"

LICENSE="Cryptopro"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"
RESTRICT="mirror strip"

src_unpack () {
    unpack ${A}
	cd ${WORKDIR}
	mv linux-amd64/* ${DISTDIR}
	rm -rf *
	mkdir ${S}
	cd ${S}
    SUFF="-64-${PV}-5.x86_64.rpm"


	rpm_unpack lsb-cprocsp-capilite${SUFF} 
	rpm_unpack lsb-cprocsp-kc1${SUFF} 
	rpm_unpack lsb-cprocsp-pkcs11${SUFF} 
	rpm_unpack cprocsp-rdr-pcsc${SUFF} 
	rpm_unpack cprocsp-rdr-gui-gtk${SUFF}
	rpm_unpack cprocsp-stunnel${SUFF}
	rpm_unpack cprocsp-rdr-rutoken${SUFF}
	rpm_unpack cprocsp-compat-altlinux-64-1.0.0-1.noarch.rpm
	rpm_unpack cprocsp-cpopenssl${SUFF}
	rpm_unpack cprocsp-cpopenssl-110${SUFF}
	rpm_unpack cprocsp-cpopenssl-110-base-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-cpopenssl-110-devel-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-cpopenssl-110-gost${SUFF}
	rpm_unpack cprocsp-cpopenssl-base-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-cpopenssl-devel-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-cpopenssl-gost${SUFF}
	rpm_unpack cprocsp-cptools-gtk${SUFF}
	rpm_unpack cprocsp-curl${SUFF}
	rpm_unpack cprocsp-drv-devel-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-ipsec-devel-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-ipsec-genpsk${SUFF}
	rpm_unpack cprocsp-ipsec-ike${SUFF}
	rpm_unpack cprocsp-rdr-cloud${SUFF}
	rpm_unpack cprocsp-rdr-cloud-gtk${SUFF}
	rpm_unpack cprocsp-rdr-cpfkc${SUFF}
	rpm_unpack cprocsp-rdr-emv${SUFF}
	rpm_unpack cprocsp-rdr-esmart${SUFF}
	rpm_unpack cprocsp-rdr-gui-gtk${SUFF}
	rpm_unpack cprocsp-rdr-infocrypt${SUFF}
	rpm_unpack cprocsp-rdr-inpaspot${SUFF}
	rpm_unpack cprocsp-rdr-jacarta-64-5.0.0.1148-4.x86_64.rpm
	rpm_unpack cprocsp-rdr-kst${SUFF}
	rpm_unpack cprocsp-rdr-mskey${SUFF}
	rpm_unpack cprocsp-rdr-novacard${SUFF}
	rpm_unpack cprocsp-rdr-pcsc${SUFF}
	rpm_unpack cprocsp-rdr-rosan${SUFF}
	rpm_unpack cprocsp-rdr-rutoken${SUFF}
	rpm_unpack cprocsp-rsa${SUFF}
	rpm_unpack cprocsp-stunnel${SUFF}
	rpm_unpack cprocsp-xer2print-${PV}-5.noarch.rpm
	rpm_unpack ifd-rutokens-1.0.1-1.x86_64.rpm
	rpm_unpack lsb-cprocsp-base-${PV}-5.noarch.rpm
	rpm_unpack lsb-cprocsp-ca-certs-${PV}-5.noarch.rpm
	rpm_unpack lsb-cprocsp-capilite${SUFF}
	rpm_unpack lsb-cprocsp-devel-${PV}-5.noarch.rpm
	rpm_unpack lsb-cprocsp-kc1${SUFF}
	rpm_unpack lsb-cprocsp-kc2${SUFF}
	rpm_unpack lsb-cprocsp-pkcs11${SUFF}
	rpm_unpack lsb-cprocsp-rdr${SUFF}
	rpm_unpack lsb-cprocsp-rdr-accord${SUFF}
	rpm_unpack lsb-cprocsp-rdr-ancud${SUFF}
	rpm_unpack lsb-cprocsp-rdr-crypton${SUFF}
	rpm_unpack lsb-cprocsp-rdr-maxim${SUFF}
	rpm_unpack lsb-cprocsp-rdr-sobol${SUFF}
}

src_install() {
    cp -vR ${S}/* ${D}/
}

#pkg_config() {
#	certmgr -inst -file ${DISTDIR}/uec.cer -store=Root
#	certmgr -inst -file ${DISTDIR}/uec2.cer -store=Root
#	/opt/cprocsp/sbin/amd64/configure_base_prov.sh kc1
#}
