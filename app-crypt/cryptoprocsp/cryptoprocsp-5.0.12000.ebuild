# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7
inherit rpm

DESCRIPTION="Cryptopro package"
HOMEPAGE="http://www.cryptopro.ru"
DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/linuxbuh/app-crypt/cryptoprocsp"
#SRC_URI="linux-amd64.tgz"
SRC_URI="$DOWNLOADPAGE/${P}.tgz"

LICENSE="Cryptopro"
SLOT="0"
KEYWORDS="~amd64"
IUSE="kc1 kc2 noarch rutokens src"

DEPEND=" sys-apps/pcsc-tools
	sys-apps/pcsc-lite
	sys-apps/lsb-release
	app-crypt/ccid"
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


if use src; then
	rpm_unpack accord_random-1-0.src.rpm
	rpm_unpack cprocsp-drv-64-5.0.12000-6.src.rpm
	rpm_unpack cprocsp-ipsec-esp-64-5.0.12000-6.src.rpm
	rpm_unpack sobol-1-8.src.rpm
fi


if use noarch; then
#	rpm_unpack cprocsp-compat-altlinux-64-1.0.0-1.noarch.rpm
#	rpm_unpack cprocsp-compat-suse-1.0.0-1.noarch.rpm
	rpm_unpack cprocsp-drv-devel-5.0.12000-6.noarch.rpm
	rpm_unpack cprocsp-ipsec-devel-5.0.12000-6.noarch.rpm
	rpm_unpack cprocsp-xer2print-5.0.12000-6.noarch.rpm
	rpm_unpack lsb-cprocsp-base-5.0.12000-6.noarch.rpm
	rpm_unpack lsb-cprocsp-ca-certs-5.0.12000-6.noarch.rpm
	rpm_unpack lsb-cprocsp-devel-5.0.12000-6.noarch.rpm
	rpm_unpack lsb-cprocsp-import-ca-certs-5.0.12000-6.noarch.rpm
fi

if use rutokens; then
	rpm_unpack ifd-rutokens_1.0.4_1.x86_64.rpm
fi

if use kc1; then
	rpm_unpack lsb-cprocsp-kc1-64-5.0.12000-6.x86_64.rpm
fi

if use kc2; then
	rpm_unpack lsb-cprocsp-kc2-64-5.0.12000-6.x86_64.rpm
fi

	rpm_unpack cprocsp-apache-modssl-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-cptools-gtk-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-curl-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-ipsec-genpsk-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-ipsec-ike-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-cloud-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-cloud-gtk-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-cpfkc-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-cryptoki-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-edoc-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-emv-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-esmart-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-gui-gtk-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-infocrypt-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-inpaspot-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-jacarta-64-5.0.0.1237-4.x86_64.rpm
	rpm_unpack cprocsp-rdr-kst-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-mskey-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-novacard-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-pcsc-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-relay-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-rosan-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-rdr-rutoken-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-stunnel-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-stunnel-msspi-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-capilite-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-pkcs11-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-rcrypt-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-rdr-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-rdr-accord-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-rdr-ancud-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-rdr-crypton-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-rdr-maxim-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-rdr-sobol-64-5.0.12000-6.x86_64.rpm
	rpm_unpack lsb-cprocsp-rdr-vityaz-64-5.0.12000-6.x86_64.rpm


	rm ${S}/lib64/ld-lsb-x86-64.so.3
}

src_install() {

    cp -vR ${S}/* ${D}/
    rm -f ${D}/etc/init.d/cprocsp
    cp -f ${FILESDIR}/cprocsp-5.0.12000 ${D}/etc/init.d/cprocsp
}

#pkg_config() {
#	certmgr -inst -file ${DISTDIR}/uec.cer -store=Root
#	certmgr -inst -file ${DISTDIR}/uec2.cer -store=Root
#	/opt/cprocsp/sbin/amd64/configure_base_prov.sh kc1
#}

pkg_postinst() {
chmod -R 777 /var/opt/cprocsp
touch /etc/debian_version
echo "jessie/sid" > /etc/debian_version
rm -f /etc/opt/cprocsp/config64.ini
#cp -f ${FILESDIR}/goodconfig64.ini /etc/opt/cprocsp/config64.ini
cp -f ${FILESDIR}/cprocsp_postinstal_all_scripts.sh /etc/opt/cprocsp/cprocsp_postinstal_all_scripts.sh
#/etc/opt/cprocsp/cprocsp_postinstal_all_scripts.sh

if use kc1; then
cp -f ${FILESDIR}/config64-kc1.ini /etc/opt/cprocsp/config64.ini
fi

if use kc2; then
cp -f ${FILESDIR}/config64-kc2.ini /etc/opt/cprocsp/config64.ini
fi

}
