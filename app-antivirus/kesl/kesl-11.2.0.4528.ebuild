# Copyright 2020-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop gnome2-utils unpacker xdg

DESCRIPTION="Kaspersky Endpoint Security для Linux Дистрибутив"
HOMEPAGE="https://kaspersky.ru/"
SRC_URI="
	amd64? (
		ftp://ftp.linuxbuh.ru/linuxbuh/app-antivirus/kesl_11.2.0-4528_amd64.deb -> "${P}"_amd64.deb
	)
"


LICENSE=""
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip"


RDEPEND="sys-kernel/calculate-sources[minimal(-),vmlinuz(-)]
	dev-lang/perl
"

S="${WORKDIR}"

src_install() {

	cp -R "${WORKDIR}/var/opt/kaspersky/kesl/install/etc" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/var/opt/kaspersky/kesl/install/opt" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/var/opt/kaspersky/kesl/install/usr" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/var/opt/kaspersky/kesl/install/var" "${D}" || die "install failed!"
}

pkg_postinst() {
    mkdir -p /var/log/kaspersky/kesl
    mkdir -p /var/log/kaspersky/kesl-user
    chmod 0777 /var/log/kaspersky/kesl-user
    touch /var/log/kaspersky/kesl/kesl_launcher.log
    elog "1. Внимание!!! Запустите /opt/kaspersky/kesl/bin/kesl-setup.pl"

}
