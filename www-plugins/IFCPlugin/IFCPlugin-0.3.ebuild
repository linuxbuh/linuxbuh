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

pkg_postinst() {
#Create logs dir
mkdir -p /var/log/ifc
mkdir -p /var/log/ifc/engine_logs
chmod 777 /var/log/ifc
chmod 777 /var/log/ifc/engine_logs

# Add VIDs and PIDs to CCID Boundle
cd /etc/update_ccid_boundle
bash ./update_ccid_boundle.sh

chmod 755 /usr/lib/mozilla/plugins/lib
chmod 755 /usr/lib/mozilla/plugins
chmod 755 /usr/lib64/mozilla/native-messaging-hosts
chmod 755 /usr/lib/mozilla/native-messaging-hosts
chmod 755 /usr/lib/mozilla
chmod 755 /usr/lib

chmod 755 /etc/opt/chrome/native-messaging-hosts
chmod 755 /etc/update_ccid_boundle
chmod 755 /etc/opt/chrome
chmod 755 /etc/opt
chmod 755 /etc

chmod 755 /opt/google/chrome/extensions
chmod 755 /opt/google/chrome
chmod 755 /opt/google
chmod 755 /opt

rm -f /etc/ifc.cfg

cp -f ${FILESDIR}/ifcx64.cfg /etc/ifc.cfg

/opt/cprocsp/bin/amd64/csptestf -absorb -certs -autoprov

cp /etc/opt/chrome/native-messaging-hosts/ru.rtlabs.ifcplugin.json /etc/chromium/native-messaging-hosts

einfo "
После установки IFCPlugin подключите ключевой носитель (флеш-накопитель, Рутокен, ESMART token и т.д.)

и выполните комманду /opt/cprocsp/bin/amd64/csptestf -absorb -certs -autoprov
"

}
