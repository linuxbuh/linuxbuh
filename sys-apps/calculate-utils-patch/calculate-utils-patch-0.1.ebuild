# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=6

inherit eutils

DESCRIPTION="calculate-utils patch python utf8"
HOMEPAGE="http://linuxbuh.ru"

LICENSE="GPL"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE=""

RESTRICT="mirror strip"

RDEPEND="sys-apps/calculate-utils"

DEPEND="${RDEPEND}"

S="${WORKDIR}"


src_install() {
cd ${WORKDIR}
mkdir -p ${D}/usr/lib/python2.7/site-packages/calculate/core/server
mkdir -p ${D}/usr/lib/python2.7/site-packages/calculate/update
cp -r ${FILESDIR}/func.py ${D}/usr/lib/python2.7/site-packages/calculate/core/server
cp -r ${FILESDIR}/update.py ${D}/usr/lib64/python2.7/site-packages/calculate/update
cp -r ${FILESDIR}/emerge_parser.py ${D}/usr/lib64/python2.7/site-packages/calculate/update
}
