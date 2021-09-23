# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7
inherit rpm

DESCRIPTION="https://www.rutoken.ru/"
HOMEPAGE="https://www.rutoken.ru/"
SRC_URI="ftp://ftp.linuxbuh.ru/linuxbuh/sys-apps/ifd-rutokens/ifd-rutokens_1.0.4_1.x86_64.rpm"
#SRC_URI="linux-amd64.tgz"
#SRC_URI="$DOWNLOADPAGE/${P}.tgz"

LICENSE="https://www.rutoken.ru/"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=" sys-apps/pcsc-tools
	sys-apps/pcsc-lite
	sys-apps/lsb-release
	app-crypt/ccid"
RDEPEND="${DEPEND}"
RESTRICT="mirror strip"

src_unpack () {
    unpack ${A}
	cd ${WORKDIR}
#	mv linux-amd64/* ${DISTDIR}
#	rm -rf *
	mkdir ${S}
	cd ${S}

#    SUFF="-64-${PV}-5.x86_64.rpm"


	rpm_unpack ifd-rutokens_1.0.4_1.x86_64.rpm

}

src_install() {
    rm ${S}/usr/lib64/pcsc/drivers/ifd-rutokens.bundle/Contents/Info.plist
    rm ${S}/usr/lib64/pcsc/drivers/ifd-rutokens.bundle/Contents/Linux/librutokens.so
    rm ${S}/usr/lib64/pcsc/drivers/ifd-rutokens.bundle/Contents/Linux/librutokens.so.1.0.4
    cp -vR ${S}/* ${D}/
}

#pkg_config() {
#	certmgr -inst -file ${DISTDIR}/uec.cer -store=Root
#	certmgr -inst -file ${DISTDIR}/uec2.cer -store=Root
#	/opt/cprocsp/sbin/amd64/configure_base_prov.sh kc1
#}

#pkg_postinst() {
#chmod -R 777 /var/opt/cprocsp
#touch /etc/debian_version
#echo "jessie/sid" > /etc/debian_version
#}
