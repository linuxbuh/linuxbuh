# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=7

inherit eutils unpacker

DESCRIPTION="Файл для persistence mode Calculate Linux"
HOMEPAGE="http://linuxbuh.ru"

SRC_URI="https://github.com/linuxbuh/linuxbuh-persistence-mode/archive/refs/tags/2021.04.15.tar.gz"

LICENSE="linuxbuh"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror"

RDEPEND=""


S="${WORKDIR}"

src_install() {
cd ${WORKDIR}
mkdir -p ${D}/etc/init.d
cp -r ${WORKDIR}/${P}/persistence ${D}/etc/init.d
}

pkg_postinst() {
chmod 0755 /etc/init.d/persistence
rc-update add persistence boot
echo "

1. Параметр persistence должен быть указан всегда, если хотим грузится в режиме persistence-mode

2. Параметр persistence_mb = - размер папки / home. Указываетя один раз для создания файла-раздела gentoo-persistence.ext4 в разделе, где лежит файл-ключ persistence-mode . По умолчанию составляет 256 мб (если не указывать).
Например, persistence_mb = 500 - будет размер 500 МБ, а persistence_mb = 1G - 1 ГБ (для указания гигабайтов надо добавить к размеру букву G, а для указаний в мегабайтах никаих букв не надо только цифры)
"
}
