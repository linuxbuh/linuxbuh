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
IUSE=""

DEPEND=" sys-apps/pcsc-tools
	sys-apps/pcsc-lite
	sys-apps/lsb-release
	app-crypt/ccid
	app-arch/rpm2targz"
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


	rpm_unpack cprocsp-rdr-pcsc${SUFF}
	rpm_unpack cprocsp-rdr-gui-gtk${SUFF}
	rpm_unpack cprocsp-stunnel${SUFF}
	rpm_unpack cprocsp-rdr-rutoken${SUFF}
	rpm_unpack cprocsp-compat-altlinux-64-1.0.0-1.noarch.rpm
	rpm_unpack cprocsp-cpopenssl${SUFF}
	rpm_unpack cprocsp-cpopenssl-base-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-cpopenssl-devel-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-cpopenssl-gost${SUFF}
	rpm_unpack cprocsp-curl${SUFF}
	rpm_unpack cprocsp-drv-devel-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-ipsec-devel-${PV}-5.noarch.rpm
	rpm_unpack cprocsp-ipsec-genpsk${SUFF}
	rpm_unpack cprocsp-ipsec-ike${SUFF}
	rpm_unpack cprocsp-rdr-emv${SUFF}
	rpm_unpack cprocsp-rdr-esmart${SUFF}
	rpm_unpack cprocsp-rdr-gui${SUFF}
	rpm_unpack cprocsp-rdr-gui-gtk${SUFF}
	rpm_unpack cprocsp-rdr-infocrypt${SUFF}
	rpm_unpack cprocsp-rdr-inpaspot${SUFF}
	rpm_unpack cprocsp-rdr-jacarta-64-3.6.408.695-4.x86_64.rpm
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

	rm ${S}/lib64/ld-lsb-x86-64.so.3
}

src_install() {
    cp -vR ${S}/* ${D}/
    rm ${D}/etc/init.d/cprocsp
    cp ${FILESDIR}/cprocsp-4.0.9963 ${D}/etc/init.d/cprocsp
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
    #rm -f /etc/opt/cprocsp/config64.ini
    #cp -f ${FILESDIR}/goodconfig64.ini /etc/opt/cprocsp/config64.ini
    cp -f ${FILESDIR}/cprocsp_postinstal_all_scripts.sh /etc/opt/cprocsp/cprocsp_postinstal_all_scripts.sh
    #/etc/opt/cprocsp/cprocsp_postinstal_all_scripts.sh

# ini файлы с форума https://forum.calculate-linux.org/t/csp-v-4-5/9989/246
#    if use lsb-kc1; then
	cp -f ${FILESDIR}/config64-kc1.ini /etc/opt/cprocsp/config64-kc1.ini
#    fi

#    if use lsb-kc2; then
	cp -f ${FILESDIR}/config64-kc2.ini /etc/opt/cprocsp/config64-kc2.ini
#    fi

    cp -f ${FILESDIR}/config64-donnstro.ini /etc/opt/cprocsp/config64-donnstro.ini
    cp -f ${FILESDIR}/config64-5.0.12000.ini /etc/opt/cprocsp/config64-5.0.12000.ini
    cp -f ${FILESDIR}/goodconfig64.ini /etc/opt/cprocsp/goodconfig64.ini


    elog "Пропишите автозапуск rc-update add cprocsp default"
    elog "Запустите /etc/init.d/cprocsp start"
    elog "ОБЯЗАТЕЛЬНО!! Запустите скрипт cprocsp_postinstal_all_scripts.sh командой 'bash /etc/opt/cprocsp/cprocsp_postinstal_all_scripts.sh'"
    elog "Eсли вам не подходит файл config64.ini созданный скриптом cprocsp_postinstal_all_scripts.sh,"
    elog "то переименуйте один из ini файлов в каталоге /etc/opt/cprocsp (например файл config64-donnstro.ini"

}

pkg_prerm ()  {

    /etc/init.d/cprocsp stop
    rc-update del cprocsp default
    rm -Rv /etc/init.d/cprocsp
    rm -Rv /etc/debian_version
    rm -Rv /var/opt/cprocsp
    rm -Rv /etc/opt/cprocsp

}

