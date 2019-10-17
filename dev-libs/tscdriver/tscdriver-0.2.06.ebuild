# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=6

MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils versionator multilib multilib-minimal unpacker

DESCRIPTION="Драйвер принтера этикеток TSC TDP-225, TDP-324"
HOMEPAGE="https://www.tscprinters.com/PYCC/support/support_download/TDP-225_Series#"

DOWNLOADPAGE="ftp://ftp.linuxbuh.ru/linuxbuh/dev-libs/tscdriver"

SRC_URI="$DOWNLOADPAGE/${P}.tar.gz"

LICENSE="linuxbuh"
SLOT="0"
KEYWORDS="x86"
IUSE=""

RESTRICT="mirror"

RDEPEND=""


S="${WORKDIR}"

src_install() {
cd ${WORKDIR}
mkdir -p ${D}/opt
mkdir -p ${D}/opt/tscdriver-0.2.06
cp -r ${WORKDIR}/${P}/* ${D}/opt/tscdriver-0.2.06
}

pkg_postinst() {
echo "Запустите /opt/tscdriver-0.2.06/install-driver для установки драйверов"
}
