# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


EAPI=6

inherit eutils

DESCRIPTION="Утилиты настройки сервера 1C:Проедприятие 8.3"
HOMEPAGE="https://linuxbuh.ru"
#SRC_URI="ftp://ftp.linuxbuh.ru/buhsoft/1C/1c83/Conf/buh/${P}.tar.gz"

LICENSE="GPL"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE=""

RESTRICT="mirror strip"

RDEPEND=""



pkg_postinst() {

cp -p ${FILESDIR}/srv1cv83.amd64 /etc/init.d/srv1cv83
#chmod 644 /etc/init.d/srv1cv83
rc-update add srv1cv83 default


groupExists () {
    grep -q "^$1:" /etc/group
}

userExists () {
    grep -q "^$1:" /etc/passwd
}

userBelongsToGroup () {
    id "$1" | grep -q "($2)"
}

[ -e /etc/init.d/srv1cv83 ] && /etc/init.d/srv1cv83 stop || :

useLegacy82=""
commonGroup="grp1cv8"

if userExists usr1cv82; then
   useLegacy82=true
fi

if ! groupExists "$commonGroup"; then
   groupadd $commonGroup >/dev/null 2>&1 || :
fi

if [ ! -z "$useLegacy82" ]; then
   username=usr1cv82
   groupname=grp1cv82
else
   username=usr1cv8
   groupname=grp1cv8

   if ! groupExists "$groupname"; then
      groupadd "$groupname" >/dev/null 2>&1 || :
   fi

   # create system user with home directory belong
   # to group grp1cv8 and $commonGroup
   # -r - system account (don't expire passwd)
   # -n don's auto create group with the same name as user
   if ! userExists $username; then
       useradd -g "$groupname" -G "$commonGroup" \
                    -m -c "1C Enterprise 8 server launcher" \
                    -r $username >/dev/null 2>&1 || :
   fi
fi

if ! userBelongsToGroup "$username" "$commonGroup"; then
   usermod -a -G "$commonGroup" "$username"
fi

dir1CVar="/var/1C"
licenseDir="$dir1CVar/licenses"
if [ ! -d "$licenseDir" ]; then
   mkdir -p "$licenseDir"
   chown $username:$commonGroup -R "$dir1CVar"
   chmod -R g+w "$dir1CVar"
fi


}