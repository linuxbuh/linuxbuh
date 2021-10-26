# Copyright 2020-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop gnome2-utils unpacker xdg

DESCRIPTION="Kaspersky Endpoint Security для Linux Агент администрирования"
HOMEPAGE="https://kaspersky.ru/"
SRC_URI="
	amd64? (
		https://products.s.kaspersky-labs.com/endpoints/keslinux10/10.1.1.6421/multilanguage-10.1.1.6421/b137f4c0/klnagent64_11.0.0-29_amd64.deb -> "${P}"_amd64.deb
	)
"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror strip"


RDEPEND="
"

S="${WORKDIR}"

src_install() {

	cp -R "${WORKDIR}/etc" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/opt" "${D}" || die "install failed!"
	cp -R "${WORKDIR}/var" "${D}" || die "install failed!"
}

pkg_postinst() {

    cp -r /opt/kaspersky/klnagent64/lib/bin/klnagent64 /etc/init.d
    elog "1. Внимание!!! Запустите /opt/kaspersky/klnagent64/lib/bin/setup/postinstall.pl"

}
