# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=7

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="Файлы настроек для подключения Calculate Linux к MS AD серверу"
HOMEPAGE="http://linuxbuh.ru"

DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/linuxbuh/sys-apps/ms-ad-linuxbuh"

SRC_URI="$DOWNLOADPAGE/${P}.tar.gz"

LICENSE="linuxbuh"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror"

RDEPEND="net-fs/samba
	 virtual/krb5"


S="${WORKDIR}"

src_install() {
cd ${WORKDIR}
mkdir -p ${D}/etc
cp -r ${WORKDIR}/${P}/etc/* ${D}/etc
}

pkg_postinst() {
rc-update add samba default
echo "

Внимание!!!
Выполните две комманды
1) dispatch-conf (ответьте на ворос u)
2) Пересоберите Samba коммандой emerge samba

"
}
