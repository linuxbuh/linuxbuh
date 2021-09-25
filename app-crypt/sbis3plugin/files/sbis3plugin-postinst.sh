#!/bin/bash

#ztime start
VERSBIS=21.4204.33
#ztime end

# готовим функции логирования
read -r -d '' common_code << EOF
# function for running command, fork output to the file and stdout, and out the exit_code
# must call like this: command_call "ls -la /tmp/000"
function command_call {
  echo -e "\$(date +%T.%3N)\t\$1" >> "\$logfile"
  command_call_cmd="\$1 2>&1 | tee -a \"\$logfile\""
  set -o pipefail
  eval \$command_call_cmd
  command_call_exit_code=\${PIPESTATUS[0]}
  set +o pipefail
  echo -e "\$(date +%T.%3N)\tExit code for: \"\$1\" is \$command_call_exit_code" >> "\$logfile"
  # восстанавливаем код возврата команды, сбрасываемый вызовом tee
  (exit \$command_call_exit_code)
}

# function for output variable name and same variable value to the file
# must call like this: variable_value kernel_name
#   which out for example: kernel_name is "linux"
#   when kernel_name contains value linux
function variable_value {
  variable_val=\$1
  echo -e "\$(date +%T.%3N)\t\c" >> "\$logfile"
  echo "\$variable_val is \"\${!variable_val}\"" >> "\$logfile"
}

# echo equivalent with fork to logfile
function echo_with_log {
  echo -e "\$(date +%T.%3N)\t\c" >> "\$logfile"
  echo "\$1" | tee -a "\$logfile"
}

# echo equivalent with redirect to logfile
function echo_log_only {
  echo -e "\$(date +%T.%3N)\t\c" >> "\$logfile"
  echo "\$1" >> "\$logfile"
}

os_name=""
os_version=""
kernel_name=\$(uname -s | tr "[:upper:]" "[:lower:]")
if [ "\$kernel_name" == "linux" ]
  then
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]
      then
        os_name=\$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
        os_version=\$(lsb_release -r | cut -d: -f2 | sed s/'^\t'//)
      else
        os_name=\$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi

if [[ "\$os_name" =~ altlinux.* ]]; then
   os_name="altlinux"
fi

#const
os_name=\$(echo "\$os_name" | tr "[:upper:]" "[:lower:]")
sbis3plugin_path=/opt/sbis3plugin

cert_path="\$sbis3plugin_path/21.4204.33/service/certs/certificate_x509.crt"
#cert_path="\$sbis3plugin_path/$VERSBIS/service/certs/certificate_x509.crt"
cert_path_pem="\$sbis3plugin_path/21.4204.33/service/certs/rootCA.pem"
#cert_path_pem="\$sbis3plugin_path/$VERSBIS/service/certs/rootCA.pem"

app_info_name="Sbis3Plugin.desktop"
app_info_dir="/usr/share/applications"
app_info_path="\$app_info_dir/\$app_info_name"

ipc_catalog="/var/run/sbisplugin"

autorun_dir="/etc/xdg/autostart"
autorun_path="\$autorun_dir/Sbis3Plugin.desktop"

#ztime Пока заремил - надо переделать
#if [ -d /usr/lib/systemd/system ]; then
#    SYSTEMD_ROOT=/usr/lib/systemd/system
#else
#    SYSTEMD_ROOT=/lib/systemd/system
#fi
#end ztime

if [ -d /etc/profile.d ]; then
    per_user_dir="/etc/profile.d"
else
    per_user_dir="/etc/X11/xinit/xinitrc.d"
fi
per_user_install="\$per_user_dir/sbis3plugin-user-install.sh"
per_user_uninstall="\$per_user_dir/sbis3plugin-user-uninstall.sh"

if [ ! -z "\$SUDO_USER" ] && [ "\$SUDO_USER" != "root" ]; then
   OWNER="\$SUDO_USER"
elif [ ! -z "\$USER" ]; then
   OWNER="\$USER"
else
   OWNER="root"
fi

log_folder="/usr/share/Sbis3Plugin/logs/\$(date +%Y%m%d)"
mkdir -p "\$log_folder"
chmod 777 "\$log_folder" &> /dev/null
logfile="\$log_folder/\$(date +%Y-%m-%d)_\$logname.log"

touch "\$logfile" &> /dev/null
chmod 777 "\$logfile" &> /dev/null

EOF

echo "$common_code" > "/usr/bin/sbis3plugin-install.common.sh"

# create install temporary log file
logname="sbis3plugin-preinstall"

# load logging functions
source "/usr/bin/sbis3plugin-install.common.sh"

echo_with_log "-------------"
echo_with_log "Preinstall script"
echo_with_log "Installer Value: $1"
echo_with_log "Установка приложения СБИС3 Плагин 21.4204.33 версии"
#echo_with_log "Установка приложения СБИС3 Плагин $VERSBIS версии"

variable_value kernel_name
variable_value os_name
variable_value os_version

# check os version
if [ -z "$os_name" ]; then
  echo_with_log "Не удалось определить ОС. Корректная работа приложения не гарантирована."
elif [ "$os_name" == "centos" ] || [ "$os_name" == "red soft" ] || 
     [ "$os_name" == "astralinuxce" ] || [ "$os_name" == "altlinux" ] ||
     [ "$os_name" == "linuxmint" ] || [ "$os_name" == "os" ] || [ "$os_name" == "debian" ]; then
  echo_with_log "ОС определена как $os_name версии $os_version."
else
  echo_with_log "ОС определена как $os_name. Корректная работа приложения в данной ОС не гарантирована."
fi

#TODO
# Подумать над установкой abrt, abrt-cli

#ztime Пока заремил - надо переделать
#FIXME Удалить после выхода 19.713
#if [ -e /opt/sbis3plugin/uninstall.sh ]; then
#   command_call "cd /opt/sbis3plugin/ && ./uninstall.sh"
#fi
#end ztime

# prepare target directory
mkdir -p "$ipc_catalog"

# stop running processes
#ztime Пока заремил - надо переделать
#echo_with_log "Остановка сервиса"
#command_call "service SBIS3Plugin stop"
#if [ $? -ne 0 ]
#  then
#    echo_with_log "Не удалось остановить сервис."
#fi
#echo_with_log "Остановка приложения"
#command_call "killall -9 sbis3plugin"
#sleep 3
#end ztime

echo_with_log "-------------"

# create install temporary log file
logname="sbis3plugin-postinstall"

# load logging functions
source "/usr/bin/sbis3plugin-install.common.sh"
echo_with_log "-------------"
echo_with_log "Postinstall script"
echo_with_log "Installer Value: $1"

# move temp directory to original
command_call "mv /opt/sbis3plugin/temp/* $sbis3plugin_path/ && rm -rf /opt/sbis3plugin/temp/"

# install cert
variable_value cert_path
echo_with_log "Установка сертификата для всех пользователей"

#ztime start заглушка
mkdir -p /usr/local/share/ca-certificates
mkdir -p /usr/share/pki/ca-trust-source/anchors
mkdir -p /usr/share/pki/trust/anchors
#ztime end

if [ -d /usr/share/pki/ca-trust-source/ ]; then
   command_call "cp \"$cert_path\" /usr/share/pki/ca-trust-source/anchors/sbis.pem"
elif [ -d /usr/share/pki/trust/ ]; then
   command_call "cp \"$cert_path\" /usr/share/pki/trust/anchors/sbis.pem"
else
   command_call "cp \"$cert_path_pem\" /usr/local/share/ca-certificates/sbis.crt"
fi
   
if [ $? -ne 0 ]
  then
    echo_with_log "Не удалось копировать сертификат. Установка не завершена."
    exit 1
fi

if command -v update-ca-trust; then
   command_call "update-ca-trust"
elif command -v update-ca-certificates; then
   command_call "update-ca-certificates"
   command_call "c_rehash"
else
   echo_with_log "Не удалось установить сертификат. Нет команды обновления сертификатов."
   exit 1
fi

if [ $? -ne 0 ]
  then
    echo_with_log "Не удалось установить сертификат. Установка не завершена."
    exit 1
fi

if [ ! -e /etc/pki/tls/certs/ca-bundle.crt ] && [ -e /etc/ssl/certs/ca-certificates.crt ]; then
   mkdir -p /etc/pki/tls/certs/
   ln -sf /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt 
fi

# remove all except *.ini files and "logs" folder
command_call "ls -d /usr/share/Sbis3Plugin/* | grep -E -v \".ini$|/logs$\" | xargs rm -rfv"

# create application icon
variable_value app_info_name
variable_value app_info_dir
variable_value app_info_path

command_call "rm -f \"$app_info_path\""

#ztime Подменяем /opt/sbis3plugin/sbis3plugin
#rm /opt/sbis3plugin/sbis3plugin
#cat > "/opt/sbis3plugin/sbis3plugin" << EOF
##!/bin/bash

#/opt/sbis3plugin/$VERSBIS/service/sbis3plugin

#EOF
#end ztime

cat > "$app_info_path" << EOF
#!/usr/bin/env xdg-open

[Desktop Entry]
Name=СБИС3 Плагин
Comment=Tensor
Exec=$sbis3plugin_path/sbis3plugin %U
Path=$sbis3plugin_path
Icon=$sbis3plugin_path/icons/default_00.png
Terminal=false
Type=Application
Encoding=UTF-8
Categories=Network;
StartupNotify=true
EOF
command_call "chmod +x \"$app_info_path\""

# register autorun
echo_with_log "Регистрация автозапуска"
variable_value autorun_dir
variable_value autorun_path
command_call "mkdir -p \"$autorun_dir\""
if [ $? -ne 0 ]
  then
    echo_with_log "Не удалось создать директорию автозапуска. Установка не завершена."
    exit 1
fi
command_call "rm -f \"$autorun_path\""
cat > "$autorun_path" << EOF
#!/usr/bin/env xdg-open

[Desktop Entry]
Name=СБИС3 Плагин
Comment=Tensor
Exec=$sbis3plugin_path/sbis3plugin %U --autostart
Path=$sbis3plugin_path
Icon=$sbis3plugin_path/icons/default_00.png
Terminal=false
Type=Application
Encoding=UTF-8
Categories=Network;
StartupNotify=true
EOF
command_call "chmod +x \"$autorun_path\""
if [ $? -ne 0 ]
  then
    echo_with_log "Не удалось создать файл автозапуска. Установка не завершена."
    exit 1
fi

# register nmh
echo_with_log "Регистрация Chrome NMH и SbisPluginConnector, проверка признака RC версии"
current_locale=$(echo $LANG | cut -d "." -f1 | tr _ -)
variable_value current_locale
if [ ! -z $current_locale ]; then
   current_locale="locale=$current_locale"
fi
command_call "\"$sbis3plugin_path/21.4204.33/service/components-registrator\" installActions $current_locale"
if [ $? -ne 0 ]
  then
    echo_with_log "Не удалось выполнить регистрацию дополнительных компонентов. Установка не завершена."
    exit 1
fi

# kill ChromeNmhTransport for change version
echo_with_log "Обновление версии CromeNmhTransport"
command_call "killall -9 ChromeNmhTransport"

# mark files as verified
command_call "touch \"$sbis3plugin_path/21.4204.33/integrity.checked\""
if [ $? -ne 0 ]
  then
    echo_with_log "Не удалось создать файл признака корректности файлов. Установка не завершена."
    exit 1
fi

# Create marker file for afterInstall action
command_call "mkdir \"/usr/share/Sbis3Plugin\""
command_call "touch \"/usr/share/Sbis3Plugin/afterInstall.marker\""
if [ $? -ne 0 ]
  then
    echo_with_log "Не удалось создать маркерный файл для выполнения afterInstall. Установка не завершена."
    exit 1
fi

# register daemon
#ztime Пока заремил - надо переделать
#echo_with_log "Регистрация демона"
#command_call "bash \"$sbis3plugin_path/21.4204.33/service/sbis-daemon-setup.sh\" --daemon-name SBIS3Plugin uninstall"

#if [ -z "$USER" ] && [ -z "$SUDO_USER" ]; then
#   echo_with_log "НЕОБХОДИМО ПЕРЕЗАГРУЗИТЬ КОМПЬЮТЕР ПОСЛЕ УСТАНОВКИ"
#fi

#command_call "bash \"$sbis3plugin_path/21.4204.33/service/sbis-daemon-setup.sh\" --force --library \"auto\" --ep \"auto\" --autorun --directory \"$sbis3plugin_path\" --executable-name sbis3plugin --add-opts \"--daemon --output_file \"/usr/share/Sbis3Plugin/logs/service_daemon.log\"\" --daemon-name SBIS3Plugin --user root install"

#if [ $? -ne 0 ]
#  then
#    echo_with_log "Не удалось зарегистрировать демона. Установка не завершена."
#    exit 1
#fi
#command_call "bash \"$sbis3plugin_path/21.4204.33/service/update_scripts/addDaemonRestart.sh\""
#command_call "service SBIS3Plugin start"
#if [ $? -ne 0 ]
#  then
#    echo_with_log "Не удалось запустить демона. Установка не завершена."
#    exit 1
#fi

#if { [ "$os_name" == "centos" ] || [ "$os_name" == "red soft" ]; } && [ -e /etc/abrt.conf ]; then
#   echo_with_log "Настройка abrtd."
#   sed -i 's,^\(MaxCrashReportsSize = \).*$,\15000,' /etc/abrt/abrt.conf >/dev/null 2>&1
#   sed -i 's,^\(OpenGPGCheck = \).*$,\1no,' /etc/abrt/abrt-action-save-package-data.conf >/dev/null 2>&1
#   sed -i 's,^\(ProcessUnpackaged = \).*$,\1yes,' /etc/abrt/abrt-action-save-package-data.conf >/dev/null 2>&1
#   systemctl restart abrtd >/dev/null 2>&1
#   for f in $SYSTEMD_ROOT/multi-user.target.wants/abrt-*.service; do
#     SRV=$(basename "$f")
#     systemctl restart "$SRV"
#   done 
#fi
#end ztime

# Wait for afterInstall result

#ztime Зашлушка
mv /usr/share/Sbis3Plugin/afterInstall.marker /usr/share/Sbis3Plugin/afterInstall.success
#ztime

i="0"
seconds_to_wait="60"
while [ $i -le $seconds_to_wait ]
do
    i=$[ $i + 1 ]

    #success
    if [ -f "/usr/share/Sbis3Plugin/afterInstall.success" ]
    then
        echo_with_log "Выполнение afterInstall успешно завершено"
        break
    fi

    #fail
    if [ -f "/usr/share/Sbis3Plugin/afterInstall.fail" ]
    then
        echo_with_log "Выполнение afterInstall завершилось с ошибкой. Установка не завершена."
        exit 1  
    fi
    
    #timeout
    if [ $i -gt $seconds_to_wait ]
    then
        echo_with_log "Не удалось выполнить afterInstall за отведенное время. Установка не завершена."
        exit 1
    fi

    sleep 1
done

# create per-user installer
variable_value per_user_dir
variable_value per_user_install
variable_value per_user_uninstall
command_call "rm -f \"$per_user_uninstall\""

cat > "$per_user_install" << EOF
#!/bin/bash

# create install temporary log file
logname="sbis3plugin-per-user-install_\$USER"

# create per user install temporary log file
per_user_install_done=".Sbis3Plugin/install.done.21.4204.33"
eval HOME_DIR=~"\$USER"
mark_file="\$HOME_DIR/\$per_user_install_done"

if [ ! -e "\$mark_file" ]; then
   # load logging functions
   source "/usr/bin/sbis3plugin-install.common.sh"
   variable_value per_user_install_done
   variable_value per_user_uninstall_done
   variable_value cert_path
   variable_value mark_file
   mark_file_dir=\$(dirname "\$mark_file")
   variable_value mark_file_dir
   command_call "mkdir -p \"\$mark_file_dir\""
   command_call "rm -f \"\$HOME_DIR/.Sbis3Plugin/uninstall.done.\"*"
   command_call "rm -f \"\$HOME_DIR/.Sbis3Plugin/install.done.\"*"
   command_call "touch \"\$mark_file\""
   if [ \$EUID -ne 0 ]; then
      # Если хранилище сертификатов Debian-based, то установки сертифика в него
      # не хватит для работы браузеров с плагином через web-socket, ибо в Debian это хранилище игнорируется браузерами
      if ! command -v update-ca-trust; then
         # install ff cert
         echo_with_log "Регистрация сертификата для Firefox"
         # first output result fo command: find "\$HOME_DIR/.mozilla/firefox" -name "cert8.db" | while read -r certDB
         command_call "find \"\$HOME_DIR/.mozilla/firefox\" -name \"cert8.db\""
         # then use this result in cycle
         cert_name="TensorCA"
         variable_value cert_name
         find "\$HOME_DIR/.mozilla/firefox" -name "cert8.db" | while read -r certDB
         do
            certdir=\$(dirname "\$certDB")
            variable_value certdir
            command_call "certutil -A -n \"\$cert_name\" -t \"TCu,Cu,Tu\" -i \"$cert_path\" -d dbm:\"\$certdir\""
         done
         # first output result fo command: find "\$HOME_DIR/.mozilla/firefox" -name "cert9.db" | while read -r certDB
         command_call "find \$HOME_DIR/.mozilla/firefox -name \"cert9.db\""
         find "\$HOME_DIR/.mozilla/firefox" -name "cert9.db" | while read -r certDB
         # then use this result in cycle
         do
            certdir=\$(dirname "\$certDB")
            variable_value certdir
            command_call "certutil -A -n \"\$cert_name\" -t \"TCu,Cu,Tu\" -i \"\$cert_path\" -d sql:\"\$certdir\""
         done

         # install chrome certs
         command_call "certutil -d sql:\$HOME_DIR/.pki/nssdb -A -t \"C,,\" -n \"TensorCA\" -i \"\$cert_path\""
      fi

      # create desktop icon
      echo_with_log "Создание иконки на рабочем столе"
      # first check running: source "\$HOME_DIR/.config/user-dirs.dirs"
      command_call "source \"\$HOME_DIR/.config/user-dirs.dirs\""
      # the immediately run: source "\$HOME_DIR/.config/user-dirs.dirs" with replacing HOME -> HOME_DIR  
      USER_DIRS=\$(sed "s/HOME/HOME_DIR/g" "\$HOME_DIR/.config/user-dirs.dirs")
      eval "\$USER_DIRS"

      command_call "cp \"\$app_info_path\" \"\$XDG_DESKTOP_DIR\""

      # mark sbis3plugin app icon as trusted
      if [ "\$os_name" == "ubuntu" ] && command -v gio; then
         dbus-launch gio set "\$XDG_DESKTOP_DIR/\$app_info_name" metadata::trusted "true"
      fi

      command_call "chmod +x \"\$XDG_DESKTOP_DIR/\$app_info_name\""
   fi
fi

EOF

chmod +x "$per_user_install"

# Нет смысла заниматься "перенаправлением" этой команды в лог, поскольку это вызов "нас самих"
# но с привилигией SUDO_USER, поскольку это приведет к двойному выводу в лог одного и того-же
# выведем в лог лишь код результата запуска
if [ "$OWNER" != "root" ]; then
   sudo -E -u "$OWNER" bash "$per_user_install"
   echo_log_only "Exit code for command: \"sudo -E -u \"$OWNER\" bash \"$per_user_install\"\" is $?"
fi

chown "$OWNER" -R "$sbis3plugin_path"

if [ "$OWNER" != "root" ] && [ ! -z "$DESKTOP_SESSION" ]; then
   success_flag_path="/usr/share/Sbis3Plugin/checking/21.4204.33"
   command_call "mkdir -p \"$success_flag_path\""
   command_call "touch \"$success_flag_path/success\""
   
   OWNER_TMPDIR=$(sudo -Hiu "$OWNER" env | grep TMPDIR)
   variable_value OWNER_TMPDIR
   
   sudo $OWNER_TMPDIR -E -u "$OWNER" "$sbis3plugin_path/sbis3plugin" "install_done" &>/dev/null &
   echo_with_log "Установка завершена."
else
   echo_with_log "Запуск плагина запрещён."
   echo_with_log "Пожалуйста, запустите приложение самостоятельно с помощью ярлыка на рабочем столе."
fi

echo_with_log "-------------"