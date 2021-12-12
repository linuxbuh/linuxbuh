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
IUSE="+lsb-kc1 lsb-kc2 +stunnel +cptools +lsb-pkcs11 +ifd-rutokens \
+rdr-jacarta +lsb-rdr-accord +lsb-rdr-ancud +lsb-rdr-crypton +lsb-rdr-maxim \
+lsb-rdr-sobol +lsb-rdr-vityaz +apache-modssl +curl +ipsec-genpsk +ipsec-ike \
+rdr-cloud +rdr-cloud-gtk +rdr-cpfkc +rdr-cryptoki +rdr-edoc +rdr-emv \
+rdr-esmart +rdr-gui-gtk +rdr-infocrypt +rdr-inpaspot +rdr-kst +rdr-mskey \
+rdr-novacard +rdr-pcsc +rdr-relay +rdr-rosan +rdr-rutoken +lsb-capilite \
+lsb-rcrypt +lsb-rdr noarch-altlinux noarch-suse noarch-ipsec-devel noarch-drv-devel \
+noarch-xer2print +noarch-lsb-base +noarch-lsb-ca-certs noarch-lsb-devel \
+noarch-lsb-import-ca-certs src-accord_random src-cprocsp-drv src-ipsec-esp src-sobol"

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

#Kryptographic Service Provider
if use lsb-kc1; then
	rpm_unpack lsb-cprocsp-kc1-64-5.0.12000-6.x86_64.rpm
fi

if use lsb-kc2; then
	rpm_unpack lsb-cprocsp-kc2-64-5.0.12000-6.x86_64.rpm
fi

#stunnel
if use stunnel; then
	rpm_unpack cprocsp-stunnel-64-5.0.12000-6.x86_64.rpm
	rpm_unpack cprocsp-stunnel-msspi-64-5.0.12000-6.x86_64.rpm
fi

#cptools gui
if use cptools; then
	rpm_unpack cprocsp-cptools-gtk-64-5.0.12000-6.x86_64.rpm
fi

#PKCS #11 library
if use lsb-pkcs11; then
	rpm_unpack lsb-cprocsp-pkcs11-64-5.0.12000-6.x86_64.rpm
fi

#drivers smartcard and token
if use ifd-rutokens; then
	rpm_unpack ifd-rutokens_1.0.4_1.x86_64.rpm
fi

if use rdr-jacarta; then
	rpm_unpack cprocsp-rdr-jacarta-64-5.0.0.1237-4.x86_64.rpm
fi

if use lsb-rdr-accord; then
	rpm_unpack lsb-cprocsp-rdr-accord-64-5.0.12000-6.x86_64.rpm
fi

if use lsb-rdr-ancud; then
	rpm_unpack lsb-cprocsp-rdr-ancud-64-5.0.12000-6.x86_64.rpm
fi

if use lsb-rdr-crypton; then
	rpm_unpack lsb-cprocsp-rdr-crypton-64-5.0.12000-6.x86_64.rpm
fi

if use lsb-rdr-maxim; then
	rpm_unpack lsb-cprocsp-rdr-maxim-64-5.0.12000-6.x86_64.rpm
fi

if use lsb-rdr-sobol; then
	rpm_unpack lsb-cprocsp-rdr-sobol-64-5.0.12000-6.x86_64.rpm
fi

if use lsb-rdr-vityaz; then
	rpm_unpack lsb-cprocsp-rdr-vityaz-64-5.0.12000-6.x86_64.rpm
fi


if use apache-modssl; then
	rpm_unpack cprocsp-apache-modssl-64-5.0.12000-6.x86_64.rpm
fi

if use curl; then
	rpm_unpack cprocsp-curl-64-5.0.12000-6.x86_64.rpm
fi

#ipsec
if use ipsec-genpsk; then
	rpm_unpack cprocsp-ipsec-genpsk-64-5.0.12000-6.x86_64.rpm
fi

if use ipsec-ike; then
	rpm_unpack cprocsp-ipsec-ike-64-5.0.12000-6.x86_64.rpm
fi

#rdr
if use rdr-cloud; then
	rpm_unpack cprocsp-rdr-cloud-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-cloud-gtk; then
	rpm_unpack cprocsp-rdr-cloud-gtk-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-cpfkc; then
	rpm_unpack cprocsp-rdr-cpfkc-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-cryptoki; then
	rpm_unpack cprocsp-rdr-cryptoki-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-edoc; then
	rpm_unpack cprocsp-rdr-edoc-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-emv; then
	rpm_unpack cprocsp-rdr-emv-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-esmart; then
	rpm_unpack cprocsp-rdr-esmart-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-gui-gtk; then
	rpm_unpack cprocsp-rdr-gui-gtk-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-infocrypt; then
	rpm_unpack cprocsp-rdr-infocrypt-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-inpaspot; then
	rpm_unpack cprocsp-rdr-inpaspot-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-kst; then
	rpm_unpack cprocsp-rdr-kst-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-mskey; then
	rpm_unpack cprocsp-rdr-mskey-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-novacard; then
	rpm_unpack cprocsp-rdr-novacard-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-pcsc; then
	rpm_unpack cprocsp-rdr-pcsc-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-relay; then
	rpm_unpack cprocsp-rdr-relay-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-rosan; then
	rpm_unpack cprocsp-rdr-rosan-64-5.0.12000-6.x86_64.rpm
fi

if use rdr-rutoken; then
	rpm_unpack cprocsp-rdr-rutoken-64-5.0.12000-6.x86_64.rpm
fi

#lsb
if use lsb-capilite; then
	rpm_unpack lsb-cprocsp-capilite-64-5.0.12000-6.x86_64.rpm
fi

if use lsb-rcrypt; then
	rpm_unpack lsb-cprocsp-rcrypt-64-5.0.12000-6.x86_64.rpm
fi

if use lsb-rdr; then
	rpm_unpack lsb-cprocsp-rdr-64-5.0.12000-6.x86_64.rpm
fi


#noarch
if use noarch-altlinux; then
	rpm_unpack cprocsp-compat-altlinux-64-1.0.0-1.noarch.rpm
fi

if use noarch-suse; then
	rpm_unpack cprocsp-compat-suse-1.0.0-1.noarch.rpm
fi

if use noarch-drv-devel; then
	rpm_unpack cprocsp-drv-devel-5.0.12000-6.noarch.rpm
fi

if use noarch-ipsec-devel; then
	rpm_unpack cprocsp-ipsec-devel-5.0.12000-6.noarch.rpm
fi

if use noarch-xer2print; then
	rpm_unpack cprocsp-xer2print-5.0.12000-6.noarch.rpm
fi

if use noarch-lsb-base; then
	rpm_unpack lsb-cprocsp-base-5.0.12000-6.noarch.rpm
fi

if use noarch-lsb-ca-certs; then
	rpm_unpack lsb-cprocsp-ca-certs-5.0.12000-6.noarch.rpm
fi

if use noarch-lsb-devel; then
	rpm_unpack lsb-cprocsp-devel-5.0.12000-6.noarch.rpm
fi

if use noarch-lsb-import-ca-certs; then
	rpm_unpack lsb-cprocsp-import-ca-certs-5.0.12000-6.noarch.rpm
fi

#src
if use src-accord_random; then
	rpm_unpack accord_random-1-0.src.rpm
fi

if use src-cprocsp-drv; then
	rpm_unpack cprocsp-drv-64-5.0.12000-6.src.rpm
fi

if use src-ipsec-esp; then
	rpm_unpack cprocsp-ipsec-esp-64-5.0.12000-6.src.rpm
fi

if use src-sobol; then
	rpm_unpack sobol-1-8.src.rpm
fi



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
    #rm -f /etc/opt/cprocsp/config64.ini
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
    elog "то переименуйте один из ini файлов в каталоге /etc/opt/cprocsp (для версии 5.0.12000 проверялся файл config64-5.0.12000.ini"

}

pkg_prerm ()  {

    /etc/init.d/cprocsp stop
    rc-update del cprocsp default
    rm -Rv /etc/init.d/cprocsp
    rm -Rv /etc/debian_version
    rm -Rv /var/opt/cprocsp
    rm -Rv /etc/opt/cprocsp

}

