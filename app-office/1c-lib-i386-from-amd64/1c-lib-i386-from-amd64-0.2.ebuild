# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=7

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="Библиотеки x86 bit для платформы 1C:Проедприятие 8.3 32 bit установленной на x86_64 операционную систему"
HOMEPAGE="http://linuxbuh.ru"

DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/linuxbuh/app-office/1c-lib-i386-from-amd64"

SRC_URI="$DOWNLOADPAGE/${P}.tar.gz"

LICENSE="linuxbuh"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RESTRICT="mirror"

RDEPEND=""


S="${WORKDIR}"

src_install() {
cd ${WORKDIR}
mkdir -p ${D}/usr
mkdir -p ${D}/usr/lib32
cp -r ${WORKDIR}/${P}/* ${D}/usr/lib32
}
