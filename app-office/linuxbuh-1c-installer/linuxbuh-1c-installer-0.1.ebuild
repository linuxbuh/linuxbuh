# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="Инсталлятор для платформы и конфигураций 1C:Проедприятие 8.3"
HOMEPAGE="http://linuxbuh.ru"

DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/linuxbuh/app-office/linuxbuh-1c-installer"

SRC_URI_X86="$DOWNLOADPAGE/${P}.i686.tar.gz"
SRC_URI_AMD64="$DOWNLOADPAGE/${P}.amd64.tar.gz"

SRC_URI="
	amd64? ( ${SRC_URI_AMD64} )
	x86? ( ${SRC_URI_X86} )
"


LICENSE="1CEnterprise_en"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror"

RDEPEND="x11-terms/xterm
	x11-misc/xdialog
	app-admin/sudo
	net-misc/wput
	app-arch/deb2targz
	net-misc/curl"


S="${WORKDIR}"

src_unpack() {
	mv ${DISTDIR}/${P}.${ARCH}.tar.gz ${WORKDIR}/${P}.tar.gz || die
	einfo "Unpacking new ${P}.tar.gz"
	unpack "./${P}.tar.gz"
}


src_install() {
cd ${WORKDIR}
mkdir -p ${D}/usr
mkdir -p ${D}/usr/bin
mkdir -p ${D}/usr/share/applications
mkdir -p ${D}/usr/share/pixmaps
cp -r ${WORKDIR}/${P}/* ${D}/usr/bin
cp -r ${FILESDIR}/linuxbuh-1c-installer.desktop ${D}/usr/share/applications/linuxbuh-1c-installer.desktop
cp -r ${FILESDIR}//linuxbuh-1c-installer.png ${D}/usr/share/pixmaps
}
