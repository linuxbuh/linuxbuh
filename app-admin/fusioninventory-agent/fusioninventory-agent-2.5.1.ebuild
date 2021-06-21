
EAPI=7

inherit perl-module 

MY_PN="FusionInventory-Agent"
DESCRIPTION="Powerful inventory and package deployment system"
HOMEPAGE="http://www.fusioninventory.org/"
SRC_URI="https://github.com/fusioninventory/fusioninventory-agent/releases/download/${PV}/FusionInventory-Agent-${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

DEPEND="
        sys-apps/dmidecode
        dev-perl/File-Which
        dev-perl/IO-Socket-SSL
        dev-perl/UNIVERSAL-require
        dev-perl/XML-TreePP
"
RDEPEND="${DEPEND}"

MY_P=${MY_PN}-${PV}
S=${WORKDIR}/${MY_P}
myconf="SYSCONFDIR=/etc/fusioninventory"

src_install() { 
        emake install
        dodir /usr/share/fusioninventory/
} 

pkg_postinst() { 
        elog "To configure Fusioninventory-agent," 
        elog "edit the file /etc/fusioninventory/agent.cfg," 
        elog "read the following web page:" 
        elog "http://www.fusioninventory.org/documentation/agent/configuration/" 
} 
