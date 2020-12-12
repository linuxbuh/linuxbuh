# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..8} )

inherit desktop eutils python-single-r1 xdg

MY_PN="PlayOnLinux"

DESCRIPTION="Set of scripts to easily install and use Windows games and software"
HOMEPAGE="https://playonlinux.com/
		https://github.com/PlayOnLinux/POL-POM-4"
SRC_URI="https://www.playonlinux.com/script_files/${MY_PN}/${PV}/${MY_PN}_${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="winbind"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="${PYTHON_DEPS}
	app-arch/p7zip
	app-arch/unzip
	app-crypt/gnupg
	app-misc/jq
	$(python_gen_cond_dep '
		dev-python/natsort[${PYTHON_MULTI_USEDEP}]
		dev-python/wxpython:4.0[${PYTHON_MULTI_USEDEP}]
	')
	media-gfx/icoutils
	|| ( net-analyzer/netcat net-analyzer/openbsd-netcat )
	net-misc/wget
	virtual/imagemagick-tools
	virtual/wine
	winbind? ( net-fs/samba[winbind] )
	x11-apps/mesa-progs
	x11-terms/xterm
"

DEPEND="${RDEPEND}
	app-arch/cabextract
"

S="${WORKDIR}/${PN}"

# TODO:
# Having a real install script
# It will let using LANGUAGES easily
# How to deal with Microsoft Fonts installation asked every time ?
# How to deal with wine version installed ? (have a better mgmt of system one)
# Look at debian pkg: https://packages.debian.org/sid/playonlinux

PATCHES=(
	"${FILESDIR}/${PN}-4.2.4-pol-bash.patch"
	"${FILESDIR}/${PN}-4.2.4-binary-plugin.patch"
	"${FILESDIR}/${PN}-4.2.6-stop-update-warning.patch"
	"${FILESDIR}/${PN}-4.4-bash-find-python.patch"
	"${FILESDIR}/${PN}-4.4-version-fix.patch"
	"${FILESDIR}/${PN}-4.4-remove-setspacing.patch"
)

src_prepare() {
	default

	python_fix_shebang .

	# remove playonmac
	rm etc/{playonmac.icns,terminal.applescript} || die

	# remove desktop integration
	rm etc/{PlayOnLinux.desktop,PlayOnLinux.directory,playonlinux-Programs.menu} || die

	sed -i -e 's/python2/python3/' Makefile
}

src_install() {
	# all things without exec permissions
	insinto "/usr/share/${PN}"
	doins -r resources lang lib etc plugins

	# bash/ install
	exeinto "/usr/share/${PN}/bash"
	find "${S}/bash" -type f -exec doexe '{}' +
	exeinto "/usr/share/${PN}/bash/expert"
	find "${S}/bash/expert" -type f -exec doexe '{}' +

	# python/ install
	python_moduleinto "/usr/share/${PN}"
	python_domodule python

	# main executable files
	exeinto "/usr/share/${PN}"
	doexe ${PN}{,-pkg,-bash,-shell,-url_handler}

	# icons
	doicon -s 128 etc/${PN}.png
	for size in 16 22 32; do
		newicon -s $size etc/${PN}$size.png ${PN}.png
	done

	doman "${FILESDIR}"/playonlinux{,-pkg}.1
	dodoc CHANGELOG.md

	make_wrapper ${PN} "./${PN}" "/usr/share/${PN}"
	make_wrapper ${PN}-pkg "./${PN}-pkg" "/usr/share/${PN}"
	make_desktop_entry ${PN} ${MY_PN} ${PN} Game
}

pkg_prerm() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog "Installed software and games with playonlinux have not been removed."
		elog "To remove them, you can re-install playonlinux and remove them using it,"
		elog "or do it manually by removing .PlayOnLinux/ in your home directory."
	fi
}
