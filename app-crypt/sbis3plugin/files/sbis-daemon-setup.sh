#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

ADD_OPTS=
AUTORUN=
DAEMON_NAME=
DIRECTORY=
#EXECUTABLE_NAME="sbis-daemon"
EXECUTABLE_NAME="sbis"
ENTRY_POINT="FcgiEntryPoint"
LIBRARY="libsbis-rpc-service300.so"
FCGI_PORT=
USER=
HTTP=
OVERRIDE_FILES=
#SYSTEMD_KILL_MODE=
#if [[ -d /usr/lib/systemd/system ]]; then
#    readonly SYSTEMD_ROOT=/usr/lib/systemd/system
#else
#    readonly SYSTEMD_ROOT=/lib/systemd/system
#fi
KILL_MODE=/etc/init.d/$EXECUTABLE_NAME

usage()
{
	[[ $# > 0 ]] && echo "$1"
	echo "Использование: $0 [опции] команда"
	echo "Допустимые команды:"
	echo "    install     Устанавливает демон"
	echo "    uninstall   Удаляет демон"
	echo "Допустимые опции:"
	echo "    --autorun             Запускать демона при старте системы"
	echo "    --daemon-name <name>  Имя демона"
	echo "    --directory <dir>     Корневой каталог демона"
	echo "    --executable-name <name>"
	echo "                          Имя исполняемого файла демона (по умолчанию: sbis-daemon)"
	echo "    --port <port>         Номер TCP-порта FCGI-сервера, запускаемого в демоне"
	echo "    --user <user>         Имя пользователя, от имени которого запускается демон"
	echo "    --sandbox <path>      Корневой каталог песочницы (опциональный параметр; если не задан, то песочница не используется)"
	echo "    --http                Использовать встроенный HTTP-сервер, а не FastCGI"
	echo "    --configure-nginx <port> <virtual-folder>"
	echo "                          Указывает, что нужно сконфигурировать web-сервер nginx, создав сайт на указаном порту и виртуальном каталоге"
	echo "    --add-opts <opts>     Дополнительные опции"
	echo "    --library <path>      Путь к загружаемой библиотеке (по умолчанию: root_dir/$LIBRARY)"
	echo "    --ep <name>           Точка входа в загружаемую библиотеку (по умолчанию: $ENTRY_POINT)"
	echo "    --override-files      При установке не проверять существование демона с указанным именем в системе. Конфигурация старого демона"
	echo "                          будет перезаписана новыми файлами конфигурации"
	echo "    --tmp-dir <path>      Путь к папке, в которую сервис будет записывать временные файлы"
	echo "    --data-dir <path>     Путь к папке, где будут храниться данные сервиса"
#	echo "    --kill-mode <mode>    Указать KillMode в systemd-скрипте. Возможные значения: control-group,process,mixed,none."
#	echo "                          Информацию о режимах см. в документации: https://www.freedesktop.org/software/systemd/man/systemd.kill.html"
	echo "    --kill-mode <mode>    Указать KillMode в скрипте. Возможные значения: control-group,process,mixed,none."
	echo "                          Информацию о режимах см. в документации: https://www.freedesktop.org/software/systemd/man/systemd.kill.html"


	exit 1
}

error()
{
	echo "$1" 1>&2
	exit $2
}

[[ $# > 0 ]] || usage

eval COMMAND=\${$#}

while [ $# -gt 1 ]; do
	case $1 in
		"--autorun")
			AUTORUN=1
			;;
		"--http")
			HTTP="--http"
			;;
		"--directory")
			shift
			DIRECTORY="$1"
			;;
		"--executable-name")
			shift
			EXECUTABLE_NAME="$1"
			;;
		"--port")
			shift
			FCGI_PORT="$1"
			;;
		"--add-opts")
			shift
			ADD_OPTS="$1"
			;;
		"--daemon-name")
			shift
			DAEMON_NAME="$1"
			;;
		"--library")
			shift
			LIBRARY="$1"
			;;
		"--ep")
			shift
			ENTRY_POINT="$1"
			;;
		"--user")
			shift
			USER="$1"
			;;
		"--sandbox")
			shift
			SANDBOX_ROOT="$1"
			;;
		"--configure-nginx")
			NGINX_ENABLED=1
			shift
			NGINX_PORT="$1"
			shift
			NGINX_VFOLDER="$1"
			;;
		"--override-files")
			OVERRIDE_FILES=1
			;;
		"--force")
			FORCE=1
			;;
		"--tmp-dir")
			shift
			TMP_DIR="$1"
			;;
		"--data-dir")
			shift
			DATA_DIR="$1"
			;;
#		"--kill-mode")
#			shift
#			SYSTEMD_KILL_MODE="$1"
#			;;
		"--kill-mode")
			shift
			KILL_MODE="$1"
			;;

		*)
			usage "ОШИБКА: Встречена неизвестная опция \"$1\""
	esac
	shift
done

#readonly SCRIPT_NAME="$SYSTEMD_ROOT/$DAEMON_NAME.service"
readonly SCRIPT_NAME="/etc/init.d/$DAEMON_NAME"

if [[ ${LIBRARY:0:1} = "/" ]]; then
	FULL_LIB_PATH="$LIBRARY"
else
	FULL_LIB_PATH="$DIRECTORY/$LIBRARY"
fi

if ! [ -z "$NGINX_ENABLED" ]
then
	[[ ${NGINX_VFOLDER:0:1} != / ]] && NGINX_VFOLDER="/$NGINX_VFOLDER"
	[[ ${NGINX_VFOLDER:(-1):1} != / ]] && NGINX_VFOLDER="$NGINX_VFOLDER/"
	NGINX_SBIS_CONFIG_ROOT="/etc/nginx/sites"
	NGINX_SITE_CONFIG_FOLDER="$NGINX_SBIS_CONFIG_ROOT/sbis_service_$NGINX_PORT.d"
	NGINX_SERVER_CONFIG="$NGINX_SBIS_CONFIG_ROOT/sbis_service_$NGINX_PORT.conf"
	NGINX_SITE_CONFIG="$NGINX_SITE_CONFIG_FOLDER/$DAEMON_NAME.srv"
	NGINX_UPSTREAM_CONFIG="$NGINX_SITE_CONFIG_FOLDER/$DAEMON_NAME.upstream"
fi

checkDirectory() {
	[ -z "$DIRECTORY" ] && usage "ОШИБКА: не задан обязательный параметр \"--directory\""
	[ ! -d "$DIRECTORY" ] && usage "ОШИБКА: указанная директория \"$DIRECTORY\" не существует или не является каталогом"
	[[ -n "$SANDBOX_ROOT" && "$(readlink -fm "$DIRECTORY")"/ == "$(readlink -fm "$SANDBOX_ROOT")"/* ]] && usage  "Ошибка: директория демона \"$DIRECTORY\" лежит внутри sandbox директории \"$SANDBOX_ROOT\""
}

checkTcpPort()
{
	local port=$1
	echo "$port" | egrep -q '^[0-9]{1,5}$' && [[ "$port" -gt 0 ]] && [[ "$port" -le 65535 ]]
}

determineFcgiPortBySystemdFile()
{
	grep 'ExecStart=' "$1" | grep ' --port' | sed -E 's/.*? --port\\? :([0-9]+).*"?/\1/'
}

checkFcgiPort()
{
	[ -z "$FCGI_PORT" ] || checkTcpPort "$FCGI_PORT" || usage "ОШИБКА: задано недопустимое значение порта FCGI-сервера \"$FCGI_PORT\""
	[ -n "$FCGI_PORT" ] && [ "$FCGI_PORT" == "$NGINX_PORT" ] && usage "ОШИБКА: значения портов FCGI-сервера \"$FCGI_PORT\" и nginx \"$NGINX_PORT\" совпадают"

	if ! [[ -n $OVERRIDE_FILES ]] && [[ "$FCGI_PORT" != "" ]]
	then

		# проверим, что этот порт не занят никаким другим сервисом СБиС
#ztime Пока заремил надо переделать
#		for fname in $SYSTEMD_ROOT/*
#		do
#			if [ -f "$fname" ] && grep -q "$EXECUTABLE_NAME" "$fname"
#			then
#				port=$(determineFcgiPortBySystemdFile "$fname")
#				[[ "$port" != "$FCGI_PORT" ]] || error "ОШИБКА: указанный порт FastCGI \"$FCGI_PORT\" занят демоном \"${fname#$SYSTEMD_ROOT/}\"" 1
#			fi
#		done
	fi
	[ -n "$FCGI_PORT" ] && [ $FCGI_PORT -lt 1024 ] && [ "$USER" != "root"  ] && usage "У указанного пользователя \"$USER\" нет прав на открытие привелигированого порта \"$FCGI_PORT\". Выберите порт из диапазона 1024...65535"
}

checkNginxConfig()
{
	if ! [ -z "$NGINX_ENABLED" ]
	then
		[ -z "$NGINX_PORT" ] && usage "ОШИБКА: не задан порт nginx-сервера"
		checkTcpPort "$NGINX_PORT" || usage "ОШИБКА: задано недопустимое значение порта NGINX \"$NGINX_PORT\""
		[ -z "$NGINX_VFOLDER" ] && usage "ОШИБКА: не задан виртуальный каталог сайта"
		[[ "`basename $DIRECTORY`" != "service" ]] && error "Невозможно создать файл конфигурации NGINX: сайт расположен в нестандартном каталоге (должен располагаться в каталоге \"service\")" 2
		local dir="`dirname "$DIRECTORY"`/"
		[[ ${NGINX_VFOLDER:(-1)} == '/' ]] || NGINX_VFOLDER="$NGINX_VFOLDER/"
		[[ "$dir" == *$NGINX_VFOLDER ]] || usage "ОШИБКА: указанный виртуальный каталог \"$NGINX_VFOLDER\" не соответствует указанному пути \"$DIRECTORY\""
		NGINX_SITE_ROOT=${dir%$NGINX_VFOLDER}

		if [ -d "$NGINX_SITE_CONFIG_FOLDER" ]
		then
			shopt -s nullglob
			for i in "$NGINX_SITE_CONFIG_FOLDER"/*.srv
			do
				local vfolder=$(grep "# Virtual folder: " "$i" | sed -E 's/^# Virtual folder: (.*)$/\1/')
				if [[ "$vfolder" == "$NGINX_VFOLDER" ]]
				then
					local srvname=$(grep "# Service: " "$i" | sed -E 's/^# Service: (.*)$/\1/')
					error "ОШИБКА: Указанный виртуальный каталог ($NGINX_VFOLDER) на порте $NGINX_PORT уже занят сервисом $srvname.
Выберите другой порт/виртуальный каталог или удалите сервис $srvname при помощи sbis-daemon-setup.sh (команда: sbis-daemon-setup.sh --daemon-name \"$srvname\" uninstall)" 1
				fi
			done
		fi

		if [ -f "$NGINX_SERVER_CONFIG" ]
		then
			# в дань совместимости с Windows-версией, на одном порту могут находиться только сервисы, расположенные в одной директории
			# (на разных виртуальных каталогах)
			# на это есть завязки в агенте обновления
			local SERVER_ROOT=$(grep "# Service location:" "$NGINX_SERVER_CONFIG" | sed -E 's/^# Service location: (.*?)$/\1/')
			[[ "$SERVER_ROOT" == "$NGINX_SITE_ROOT" ]] || error "На порте $NGINX_PORT установлен сервис, расположенный в директории $SERVER_ROOT. На один порт можно установить только сервисы, имеющие одинаковое расположение, но отличающиеся виртуальным портом. Вы пытаетесь установить сервис, расположенный в директории $NGINX_SITE_ROOT" 1
		fi
	fi
}

checkUser()
{
	[ -z "$USER" ] && usage "Не задан обязательный параметр \"--user\""
	if [ -f /etc/sbis-sandbox ] || [ -z "$SANDBOX_ROOT" ]; then
		getent passwd $USER  > /dev/null || error "Пользователь \"$USER\" не найден" 1
	else
		if ! cat "$SANDBOX_ROOT/etc/passwd" | grep -e "^$USER" > /dev/null
		then
			echo "$USER:x:1000:1000:sbis:/home/sbis:/bin/bash" >> "$SANDBOX_ROOT/etc/passwd"
			echo "Создан пользователь \"$USER\" в песочнице"
		fi
	fi
}

checkName()
{
	[ -z "$DAEMON_NAME" ] && usage "Не задан обязательный параметр \"--daemon-name\""
	[[ "$DAEMON_NAME" =~ ^[-0-9a-zA-Zа-яА-Я_\ ]+$ ]] || error "ОШИБКА: указанное имя демона ($DAEMON_NAME) содержит недопустимые символы" 1
}

checkNameUniqueness()
{
	[ -f "$SCRIPT_NAME" ] && error "ОШИБКА: демон с указанным именем ($DAEMON_NAME) уже существует.
Выберите другое имя или удалите установленный демон утилитой sbis-daemon-setup.sh (команда: sbis-daemon-setup.sh --daemon-name \"$DAEMON_NAME\" uninstall)" 1
}

checkLibPath()
{
	[ -z $LIBRARY ] && usage "Не задан обязательный параметр  \"--library\""
	[ -z "$FORCE" ] || return 0
	[ -r "$FULL_LIB_PATH" ] || error "ОШИБКА: указан некорректный путь до библиотеки ($FULL_LIB_PATH)" 1
}

checkEntryPoint()
{
	[ -z $ENTRY_POINT ] && usage "Не задан обязательный параметр \"--ep\""
	[ -z "$FORCE" ] || return 0
	if which nm 2>&1 > /dev/null
	then
		{ nm -D --defined-only "$FULL_LIB_PATH" | grep -q "$ENTRY_POINT"; } || \
		{
			error "Точка входа \"$ENTRY_POINT\" не найдена в библиотеке \"$FULL_LIB_PATH\"" 1
		}
	fi
}

checkTmpDir()
{
	[ -n $TMP_DIR ] && [ ! -d $TMP_DIR ] && usage "ОШИБКА: директория, указанная в --tmp-dir (\"$TMP_DIR\"), не существует или не является каталогом"
}

checkDataDir()
{
	[ -n "$DATA_DIR" ] && [ ! -d "$DATA_DIR" ] && usage "ОШИБКА: директория, указанная в --data-dir (\"$DATA_DIR\"), не существует или не является каталогом"
}

checkSandboxRoot()
{
	if [[ -f "/etc/sbis-sandbox" ]]
	then
		# случай, когда скрипт установки запущен из песочницы. В таком случае если явно задан параметр --sandbox,то он должен совпадать
		# со значением, указанным в /etc/sbis-sandbox. Если --sandbox не указан, то выставляем его автоматически
		real_sb_root=$(grep root /etc/sbis-sandbox | sed -E 's/^root=(.*)$/\1/') || error "Не удалось разобрать файл /etc/sbis-sandbox" 1
		if [[ -n "$SANDBOX_ROOT" ]]
		then
			SANDBOX_ROOT="$real_sb_root"
		elif [[ "$SANDBOX_ROOT" != "$real_sb_root" ]]
		then
			error "ОШИБКА: Задано некорректное значение параметра \"--sandbox\". Скрипт установки был запущен из песочницы, расположенной в директории \"$real_sb_root\". Путь, указанный в параметре должен совпадать с реальным местоположением песочницы" 1
		fi
	else
		[[ -n "$SANDBOX_ROOT" && ! -d "$SANDBOX_ROOT" ]] && error  "Ошибка: указанная директория песочницы \"$SANDBOX_ROOT\" не существует или не является каталогом" 1
	fi
}

checkKillMode()
{
#	[ -z $SYSTEMD_KILL_MODE ] ||
#	[[ "$SYSTEMD_KILL_MODE" == "control-group" ]] ||
#	[[ "$SYSTEMD_KILL_MODE" == "process" ]] ||
#	[[ "$SYSTEMD_KILL_MODE" == "mixed" ]] ||
#	[[ "$SYSTEMD_KILL_MODE" == "none" ]] ||
#	error "Ошибка: указано некорректное значение параметра --kill-mode: \"$SYSTEMD_KILL_MODE\"" 1
	[ -z $KILL_MODE ] ||
	[[ "$KILL_MODE" == "control-group" ]] ||
	[[ "$KILL_MODE" == "process" ]] ||
	[[ "$KILL_MODE" == "mixed" ]] ||
	[[ "$KILL_MODE" == "none" ]] ||
	error "Ошибка: указано некорректное значение параметра --kill-mode: \"$KILL_MODE\"" 1

}

generate_nginx_config()
{
	[ -z $NGINX_ENABLED ] && return 0

	mkdir -p "$NGINX_SBIS_CONFIG_ROOT" || error "Не удалось создать директорию \"$NGINX_CONFIG_ROOT\"" 1
	mkdir -p "$NGINX_SITE_CONFIG_FOLDER" || error "Не удалось создать директорию \"$NGINX_SITE_CONFIG_FOLDER\"" 2

	local NGINX_COMMON_CONFIG_FOLDER="/etc/nginx/conf.d"
	local NGINX_SBIS_COMMON_CONFIG="/etc/nginx/conf.d/sbis.conf"
	mkdir -p "$NGINX_COMMON_CONFIG_FOLDER" || error "Не удалось создать директорию \"$NGINX_COMMON_CONFIG_FOLDER\""
	echo \
"# Default nginx log format
log_format	sbis	'[\$hostname] [\$host] [\$remote_addr] [\$http_x_forwarded_for] '
			'[\$cookie_sid] [\$http_x_sbissessionid] [\$http_x_request_id] '
			'[\$time_local] [\$http_x_requestdatetime] '
			'[\$request] '
			'[\$http_x_calledmethod] [\$http_x_currentmethod] '
			'[\$status] [\$request_time] [\$request_length] <- '
			'[\$upstream_addr] [\$upstream_status] [\$upstream_response_time] [\$upstream_cache_status]'
			'[\$http_referer] [\$http_user_agent] '
			'[\$http_x_uniq_id]'
			'';

include $NGINX_SBIS_CONFIG_ROOT/*.conf;" > "$NGINX_SBIS_COMMON_CONFIG"

	if ! [ -s "$NGINX_SERVER_CONFIG" ]
	then
		# если нет файла настроек сервера на данном порту, то создаём его
		echo \
"# Service location: ${NGINX_SITE_ROOT}
# Port: $NGINX_PORT

include $NGINX_SITE_CONFIG_FOLDER/*.upstream;

server {
	listen	$NGINX_PORT;
	client_max_body_size 100m;
	access_log   /var/log/nginx/access_$NGINX_PORT.log sbis;

	# Shows some statistics
	location = /!nginx/status {
		stub_status on;
		access_log off;
		allow 127.0.0.0/8;
		allow 192.168.0.0/16;
		allow 10.0.0.0/8;
		allow 172.16.0.0/12;
		deny all;
	}

	include $NGINX_SITE_CONFIG_FOLDER/*.srv;
}" > "$NGINX_SERVER_CONFIG" || error "Не удалось создать файл конфигурации nginx \"$NGINX_SERVER_CONFIG\"" 3
	fi

	local NGINX_SRV_LOCATION="$NGINX_VFOLDER"service

	echo \
"# Service: $DAEMON_NAME
# Port: $NGINX_PORT
# Virtual folder: $NGINX_VFOLDER
# FastCGI port: $FCGI_PORT
# Service location: ${NGINX_SITE_ROOT}

location $NGINX_SRV_LOCATION {
	fastcgi_split_path_info ^.*/service(/sbis-rpc-service300.dll)?(.*)$;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
	fastcgi_pass $DAEMON_NAME;
	include fastcgi_params;
	fastcgi_connect_timeout 3600s;
	fastcgi_send_timeout    3600s;
	fastcgi_read_timeout    3600s;
}" > "$NGINX_SITE_CONFIG" || error "Не удалось создать файл конфигурации nginx \"$NGINX_SITE_CONFIG\"" 4

	echo \
"# Service: $DAEMON_NAME
# Port: $NGINX_PORT
# Virtual folder: $NGINX_VFOLDER
# FastCGI port: $FCGI_PORT
# Service location: ${NGINX_SITE_ROOT}

upstream $DAEMON_NAME {
	server 127.0.0.1:$FCGI_PORT;
}" > "$NGINX_UPSTREAM_CONFIG" || error "Не удалось создать файл конфигурации nginx \"$NGINX_UPSTREAM_CONFIG\"" 5
}

generate_systemd_script()
{
if [[ -f /usr/bin/mkdir ]]; then
    MKDIR_PATH=/usr/bin/mkdir
else
    MKDIR_PATH=/bin/mkdir
fi
if [[ -f /usr/bin/chmod ]]; then
    CHMOD_PATH=/usr/bin/chmod
else
    CHMOD_PATH=/bin/chmod
fi
	echo "[Unit]
Description=SBIS Service
After=network.target network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=forking
LimitNOFILE=1000000
LimitCORE=infinity
User=$USER
PermissionsStartOnly=true
ExecStartPre=-$MKDIR_PATH -p /var/run/sbis
ExecStartPre=$CHMOD_PATH 777 /var/run/sbis
PIDFile=$SANDBOX_ROOT/var/run/sbis/$DAEMON_NAME.pid
ExecStart=\"$DIRECTORY/$EXECUTABLE_NAME\" --name \"$DAEMON_NAME\" --library \"$LIBRARY\" --ep \"$ENTRY_POINT\" start $HTTP $ADD_OPTS
ExecStop=\"$DIRECTORY/$EXECUTABLE_NAME\" --name \"$DAEMON_NAME\" stop
WorkingDirectory=$DIRECTORY" > "$SCRIPT_NAME"

	if [[ -n "$SYSTEMD_KILL_MODE" ]]; then
		echo "KillMode=$SYSTEMD_KILL_MODE" >> "$SCRIPT_NAME"
	fi

	if [[ -n "$SANDBOX_ROOT" ]]; then
		echo "RootDirectory=$SANDBOX_ROOT" >> "$SCRIPT_NAME"
	fi

	if [[ -n "$TMP_DIR" ]]; then
		echo "Environment=\"TMPDIR=$TMP_DIR\"" >> "$SCRIPT_NAME"
	fi

	[ -n "$DATA_DIR" ] && echo "Environment=\"SBIS_DATADIR=$DATA_DIR\"" >> "$SCRIPT_NAME"

	return 0
}

stop_daemon()
{
	systemctl stop "${DAEMON_NAME}.service"
}

setup_autorun()
{
	if [[ $? && -n $AUTORUN ]]; then
		systemctl enable "$DAEMON_NAME"
	else
		systemctl disable "$DAEMON_NAME"
	fi
}

delete_systemd_script()
{
	systemctl disable "$DAEMON_NAME"
	rm -vf "$SCRIPT_NAME"
}

reload_systemd_config()
{
	systemctl --system daemon-reload
}

remove_nginx_cfg()
{
	# определим по systemd-файлу порт FastCGI
	[ -f "$SCRIPT_NAME" ] || error "ОШИБКА: Демон \"$DAEMON_NAME\" не найден в системе" 1
	local FCGI_PORT=$(determineFcgiPortBySystemdFile "$SCRIPT_NAME")
	if [ -n "$FCGI_PORT" ]
	then
		# ищем конфиг nginx, который работает с этим портом
		shopt -s nullglob
		for fname in /etc/nginx/sites/*/*.srv
		do
			if grep -qx "^# FastCGI port: $FCGI_PORT\$"  "$fname"
			then
				rm -vf "$fname"
				rm -vf "${fname%srv}upstream"
				local dir="$(dirname $fname)"
				rmdir -v --ignore-fail-on-non-empty "$dir" && rm -vf "${dir%d}conf"
			fi
		done
	fi
	return 0
}

case $COMMAND in
	install)
		checkSandboxRoot
		checkName
		[[ -n $OVERRIDE_FILES ]] || checkNameUniqueness
		checkFcgiPort
		checkDirectory
		checkUser
		checkLibPath
		checkEntryPoint
		checkNginxConfig
		checkTmpDir
		checkKillMode
		
		[ ! -z "$FCGI_PORT" ] && ADD_OPTS="$ADD_OPTS --port :$FCGI_PORT"
		
		echo "====================================="
		echo "Registering daemon \"$DAEMON_NAME\""
		echo "-------------------------------------"
		echo "directory:   $DIRECTORY"
		echo "user:        $USER"
		[ -n "$FCGI_PORT" ] && echo "port:        $FCGI_PORT"
		echo "library:     $LIBRARY"
		echo "entry point: $ENTRY_POINT"
		
		if [[ -n "$AUTORUN" ]]; then
			echo "autorun:     true"
		else
			echo "autorun:     false"
		fi

		if [[ -n "$SANDBOX_ROOT" ]]; then
			echo "sandbox root: $SANDBOX_ROOT"
		fi
		
		if ! [[ -z "$NGINX_ENABLED" ]]; then
			echo "nginx port:  $NGINX_PORT"
			echo "site root:   $NGINX_SITE_ROOT"
			echo "virtual folder: $NGINX_VFOLDER"
		fi

		if ! [[ -z "$TMP_DIR" ]]; then
			echo "tmp directory:  $TMP_DIR"
		fi

		[ -n "$DATA_DIR" ] && echo "data directory: $DATA_DIR"
		
		echo "====================================="
		generate_systemd_script && reload_systemd_config && setup_autorun && generate_nginx_config && echo "OK"
		;;
	uninstall)
		checkName
		[ -f "$SCRIPT_NAME" ] || error "Демон \"$DAEMON_NAME\" не установлен в системе" 1
		echo "====================================="
		echo "unregistering daemon \"$DAEMON_NAME\""
		echo "====================================="
		stop_daemon
		remove_nginx_cfg && delete_systemd_script && reload_systemd_config && echo "OK"
		;;
	*)
		usage "ОШИБКА: Неизвестная команда \"$COMMAND\""
esac

true

