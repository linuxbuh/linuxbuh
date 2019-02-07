# -*- coding: utf-8 -*-

# Copyright 2015-2016 Mir Calculate. http://www.calculate-linux.org
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

import hashlib

import os
from os import path

import re
import sys
reload(sys);
sys.setdefaultencoding('utf8')
from calculate.lib.utils.colortext.palette import TextState
from calculate.lib.utils.tools import ignore
from calculate.lib.utils.git import Git, GitError
from calculate.lib.utils.portage import (EmergePackage, PackageList,
                                         EmergeUpdateInfo,
                                         EmergeRemoveInfo)

Colors = TextState.Colors
import pexpect
from calculate.lib.utils.files import (getProgPath, readLinesFile,
                                       listDirectory,
                                       writeFile, readFile)
from calculate.lib.utils.colortext.output import XmlOutput
from calculate.lib.utils.colortext.converter import (ConsoleCodes256Converter,
                                                     XmlConverter)
from calculate.lib.cl_log import log

from calculate.lib.cl_lang import setLocalTranslate, getLazyLocalTranslate, _

setLocalTranslate('cl_update3', sys.modules[__name__])
__ = getLazyLocalTranslate(_)

linux_term_env = {'TERM': 'linux'}

class EmergeError(Exception):
    """
    Ошибка при сборке пакетов
    """


class EmergeNeedRootError(EmergeError):
    pass


class CommandExecutor(object):
    """
    Запуск программы для объекта Emerge
    """
    logfile = '/var/log/calculate/lastcommand.log'

    def __init__(self, cmd, params, env=None, cwd=None, logfile=None):
        self.cwd = cwd
        self.env = env or dict(os.environ)
        self.env.update({'EINFO_QUIET': 'NO'})
        self.env.update(linux_term_env)
        self.cmd = cmd
        self.params = params
        self.child = None
        if logfile:
            self.logfile = logfile

    def get_command(self):
        return [self.cmd] + list(self.params)

    def execute(self):
        if self.child is None:
            command_data = self.get_command()
            self.child = pexpect.spawn(command_data[0], command_data[1:],
                                       logfile=open(self.logfile, 'w'),
                                       env=self.env, cwd=self.cwd, timeout=None)
        return self.child

    def close(self):
        if self.child is not None:
            self.child.close()
            self.child = None

    def success(self):
        if self.child:
            self.child.read()
            if self.child.isalive():
                self.child.wait()
            return self.child.exitstatus == 0
        return False

    def failed(self):
        return not self.success()

    def send(self, s):
        if self.child:
            self.child.send(s)


class EmergeCommand(CommandExecutor):
    """
    Запуск emerge для последующего анализирования
    """
    # параметры по умолчанию
    default_params = ["-av", "--color=y", "--nospinner"]
    emerge_cmd = getProgPath("/usr/bin/emerge")

    def __init__(self, packages, extra_params=None, env=None, cwd=None,
                 logfile=None, emerge_default_opts=None, env_update=None,
                 use=""):
        extra_params = extra_params or []
        if env is None:
            if emerge_default_opts is None:
                env = {'CLEAN_DELAY': '0'}
            else:
                env = {
                    'CLEAN_DELAY': '0',
                    'EMERGE_DEFAULT_OPTS': re.sub(
                        r'(?:^|\s)(--columns)(?=\s|$)', '',
                        emerge_default_opts)
                }
                if use:
                    env["USE"] = use
            env.update(os.environ)
        if env_update is not None:
            env.update(env_update)

        params = self.default_params + extra_params + packages
        super(EmergeCommand, self).__init__(self.emerge_cmd, params=params,
                                            env=env, cwd=cwd, logfile=logfile)


def Chroot(chroot_path, obj):
    """
    Преобразовать команду (экземпляр объекта) в chroot
    :param obj: экземпляр команды
    :param chroot_path: путь для chroot
    :return:
    """
    old_get_command = obj.get_command

    def get_command():
        chrootCmd = '/usr/bin/chroot'
        bashCmd = '/bin/bash'
        bash_command = (
            "env-update &>/dev/null;"
            "source /etc/profile &>/dev/null;"
            "{cmd}".format(cmd=" ".join(old_get_command())))
        return [chrootCmd, chroot_path, bashCmd, "-c", bash_command]
    obj.get_command = get_command
    return obj


def Linux32(obj):
    """
    Преобразовать команду (экземпляр объекта) в вызов под linux32
    :param obj: экземпляр команды
    :return:
    """
    old_get_command = obj.get_command

    def get_command():
        return ["/usr/bin/linux32"] + old_get_command()
    obj.get_command = get_command
    return obj


class InfoBlockInterface(object):
    """
    Интерфейс для информационного блока
    """
    action = None
    token = None
    result = None
    text_converter = ConsoleCodes256Converter(XmlOutput())

    def get_block(self, child):
        pass

    def add_element(self, element):
        """
        :type element: InfoBlockInterface
        """
        pass


class EmergeInformationBlock(InfoBlockInterface):
    _color_block = "(?:\033\[[^m]+?m)?"
    _new_line = "(?:\r*\n)"
    end_token = ["\n"]
    re_block = None
    re_match_type = type(re.match("", ""))
    re_type = type(re.compile(""))

    def __init__(self, parent):
        """
        :type parent: InfoBlockInterface
        """
        self.result = None
        self.text_converter = parent.text_converter
        self.parent = parent
        self.parent.add_element(self)
        self.children = []

    def add_element(self, element):
        """
        :type element: InfoBlockInterface
        """
        self.children.append(element)

    def __str__(self):
        if type(self.result) == self.re_match_type:
            return self.result.group()
        else:
            return self.result or ""

    def __nonzero__(self):
        return bool(self.result)

    def __len__(self):
        if self.result is None:
            return 0
        else:
            return len(self.result)

    def __contains__(self, item):
        if self.result is None:
            return False
        else:
            return item in str(self)

    def _get_text(self, result):
        """
        Получить результат из регулярки и преобразовать его через self.converter
        """
        if result:
            return self.text_converter.transform(result.rstrip())
        return ""

    def get_block(self, child):
        try:
            token = child.match
            if type(self.end_token) == self.re_type:
                child.expect(self.end_token)
                match = child.match.group()
            else:
                child.expect_exact(self.end_token)
                match = child.match
            self.get_data(self.re_block.search(
                token + child.before + match))
        except pexpect.EOF:
            child.buffer = "".join(
                [x for x in (child.before, child.after, child.buffer)
                 if type(x) == str])

    def get_data(self, match):
        self.result = self._get_text(match.group(1))


class InstallPackagesBlock(EmergeInformationBlock):
    """
    Блок emerge содержащий список пакетов для установки
    """
    list = PackageList([])
    remove_list = PackageList([])
    block_packages = False
    _new_line = EmergeInformationBlock._new_line
    _color_block = EmergeInformationBlock._color_block
    token = "\n["
    end_token = ["\r\n\r", "\n\n"]

    re_block = re.compile(r"((?:^\[.*?{nl})+)".format(nl=_new_line),
                          re.MULTILINE)
    re_blocks = re.compile(r"\[{c}blocks{c} {c}b".format(c=_color_block))

    def get_data(self, match):
        super(InstallPackagesBlock, self).get_data(match)
        list_block = XmlConverter().transform(self.result).split('\n')
        self.list = PackageList(map(EmergeUpdateInfo, list_block))
        self.remove_list = PackageList(map(EmergeRemoveInfo, list_block))
        self.block_packages = any(self.re_blocks.search(x) for x in list_block)


class UninstallPackagesBlock(EmergeInformationBlock):
    """
    Блок emerge содержащий список удаляемых пакетов
    """
    list = PackageList([])
    verbose_result = ""
    _new_line = EmergeInformationBlock._new_line
    _color_block = EmergeInformationBlock._color_block
    token = ["Calculating removal order",
             "These are the packages that would be unmerged"]
    end_token = re.compile("All selected packages:.*\n")
    re_block = re.compile(
        r"(?:{token}).*?{nl}(.*){nl}All selected packages: (.*?){nl}".
        format(token="|".join(token),
               nl=_new_line, c=_color_block), re.DOTALL)

    def get_data(self, match):
        re_clean = re.compile(
            "^.*?({token}).*?{c}{nl}".format(token="|".join(self.token),
                                             nl=self._new_line,
                                             c=self._color_block), re.DOTALL)
        verbose_result = re_clean.sub("", match.group(1))
        self.verbose_result = self._get_text(verbose_result)
        self.result = self._get_text(match.group(2))
        list_block = XmlConverter().transform(self.result).split()
        self.list = PackageList(map(EmergePackage, list_block))


class GroupEmergeInformationBlock(EmergeInformationBlock):
    """
    Группа блоков
    """
    def get_block(self, child):
        self.children_get_block(child)
        self.result = True

    def children_get_block(self, child):
        for block in self.children:
            block.get_block(child)

    def children_action(self, child):
        for block in (x for x in self.children if x.result and x.action):
            if block.action(child) is False:
                return False

    def action(self, child):
        self.children_action(child)
        return False


class FinishEmergeGroup(GroupEmergeInformationBlock):
    """
    Блок завершения команды
    """
    token = pexpect.EOF
    # регуляреное выражение, определяющее содержит ли блок
    # сообщения об ошибках
    re_failed = re.compile(
        r"Fetch instructions for \S+:|"
        r"The following.*are necessary to proceed|"
        r"!!! Multiple package .* slot have been pulled|"
        r"no ebuilds to satisfy|"
        r"Dependencies could not be completely resolved due to",
        re.MULTILINE)

    def get_block(self, child):
        if child.isalive():
            child.wait()
        if child.exitstatus != 0 or self.re_failed.search(child.before):
            self.children_get_block(child)
        else:
            self.result = True


class PrepareErrorBlock(EmergeInformationBlock):
    """
    Блок информации с ошибками при получении списка устанавливаемых пакетов
    """
    token = None

    re_drop = re.compile("news items need reading|"
                         "Use eselect news|"
                         "Calculating dependencies|"
                         "to read news items|"
                         "Local copy of remote index is up-to-date|"
                         "These are the packages that would be merged|"
                         "Process finished with exit code")
    re_multi_empty_line = re.compile("(?:<br/>){3,}", re.DOTALL)
    re_strip_br = re.compile("^(?:<br/>)+|(?:<br/>)+$", re.DOTALL)

    def remove_needless_data(self, data):
        return "\n".join([x for x in data.split('\n')
                          if not self.re_drop.search(x)])

    def strip_br(self, data):
        return self.re_strip_br.sub(
            "",
            self.re_multi_empty_line.sub("<br/><br/>", data))

    def get_block(self, child):
        self.result = self.strip_br(
            self._get_text(self.remove_needless_data(child.before)))

    def action(self, child):
        raise EmergeError(_("Emerge failed"))


class DownloadSizeBlock(EmergeInformationBlock):
    """
    Размер скачиваемых обновлений
    """
    token = "Size of downloads:"

    re_block = re.compile(r"Size of downloads:\s(\S+\s\S+)")

    def __str__(self):
        if self.result:
            return self.result
        else:
            return "0 kB"

class SkippedPackagesBlock(EmergeInformationBlock):
    """
    Размер скачиваемых обновлений
    """
    token = "The following update has been skipped"
    end_token = ["For more information, see the MASKED"]

    re_block = re.compile(
        r"(The following update has.*?)(?=For more information)", re.S)

    def __str__(self):
        if self.result:
            return self.result
        else:
            return ""

class QuestionGroup(GroupEmergeInformationBlock):
    """
    Группа блоков разбора вопросов от emerge
    """
    token = "Would you like"
    end_token = ["]", "\n"]
    _color_block = EmergeInformationBlock._color_block
    re_block = re.compile(
        "(Would you.*)\[{c}Yes{c}/{c}No{c}".format(c=_color_block))

    def get_block(self, child):
        try:
            before = child.before
            token = child.match
            if type(self.end_token) == self.re_type:
                child.expect(self.end_token)
                match = child.match.group()
            else:
                child.expect_exact(self.end_token)
                match = child.match
            data = token + child.before + match
            child.before = before
            for block in self.children:
                child.match = re.search(block.token, data)
                block.get_block(child)
                if block.result:
                    break
        except pexpect.EOF:
            child.buffer = "".join(
                [x for x in (child.before, child.after, child.buffer)
                 if type(x) == str])

class QuestionChangeConfigBlock(GroupEmergeInformationBlock):
    """
    Вопрос об изменении конфигурационных файлов
    """
    token = "Would you like to add these changes to your config files"

    def get_block(self, child):
        if child.match:
            self.result = self.token
            self.children_get_block(child)

    def action(self, child):
        if self.result:
            child.send("no\n")
            if child.isalive():
                child.wait()
            self.children_action(child)


class QuestionBlock(EmergeInformationBlock):
    """
    Блок вопроса
    """
    default_answer = "yes"
    token = "Would you"

    def get_block(self, child):
        if child.match:
            self.result = self.token

    def action(self, child):
        if self.result:
            child.send("%s\n" % self.default_answer)
            return False


class NeedRootBlock(EmergeInformationBlock):
    """
    Пользователь не явеляется root
    """
    token = "This action requires superuser access"

    def get_data(self, child):
        self.result = True

    def action(self, child):
        raise EmergeNeedRootError(_("This action requires superuser access"))


class NotifierInformationBlock(EmergeInformationBlock):
    """
    Информационный блок поддерживающий observing
    """
    def __init__(self, parent):
        super(NotifierInformationBlock, self).__init__(parent)
        self.observers = []

    def get_data(self, match):
        self.result = match

    def add_observer(self, f):
        self.observers.append(f)

    def clear_observers(self):
        self.observers = []

    def remove_observer(self, f):
        if f in self.observers:
            self.observers.remove(f)

    def notify(self, observer, groups):
        observer(groups)

    def action(self, child):
        if self.result and self.observers:
            groups = self.result.groups()
            for observer in self.observers:
                self.notify(observer, groups)


class EmergingPackage(NotifierInformationBlock):
    """
    Запуск устанавливаемого пакета

    ObserverFunc: (package, num=number, max_num=number, binary=binary)
    """
    _color_block = EmergeInformationBlock._color_block
    token = ">>> Emerging "
    re_block = re.compile(
        "Emerging (binary )?\({c}(\d+){c} "
        "of {c}(\d+){c}\) {c}([^\s\033]+){c}".format(c=_color_block))

    def notify(self, observer, groups):
        observer(EmergePackage(groups[3]), num=groups[1], max_num=groups[2],
                 binary=bool(groups[0]))


class UnemergingPackage(NotifierInformationBlock):
    """
    Запуск устанавливаемого пакета

    ObserverFunc: (package, num=number, max_num=number)
    """
    _color_block = EmergeInformationBlock._color_block
    token = ">>> Unmerging"
    re_block = re.compile(
        r"Unmerging (?:\({c}(\d+){c} "
        r"of {c}(\d+){c}\) )?(\S+)\.\.\.".format(c=_color_block))

    def notify(self, observer, groups):
        observer(EmergePackage(groups[2]), num=groups[0], max_num=groups[1])


class FetchingTarball(NotifierInformationBlock):
    """
    Происходит скачивание архивов
    """
    token = "Saving to:"
    re_block = re.compile("Saving to:\s*[‘'](\S+)?['’]")

    def notify(self, observer, groups):
        observer(groups[0])


class InstallingPackage(NotifierInformationBlock):
    """
    Запуск устанавливаемого пакета

    ObserverFunc: (package, binary=binary)
    """
    _color_block = EmergeInformationBlock._color_block
    binary = None

    token = ">>> Installing "
    re_block = re.compile(
        "Installing \({c}(\d+){c} "
        "of {c}(\d+){c}\) {c}([^\s\033]+){c}".format(c=_color_block))

    def notify(self, observer, groups):
        strpkg = str(EmergePackage(groups[2]))
        binary = bool(self.binary and strpkg in self.binary)
        observer(EmergePackage(groups[2]), binary=binary)

    def mark_binary(self, package):
        if self.binary is None:
            self.binary = []
        self.binary.append(str(package))


class EmergeingErrorBlock(EmergeInformationBlock):
    """
    Блок содержит информацию об ошибке во время сборки пакета
    """
    token = ["* ERROR: ", " * \033[39;49;00mERROR: "]
    end_token = "Working directory:"
    re_block = re.compile("ERROR: (\S*) failed \([^)]+\).*?"
                          "The complete build log is located at '([^']+)",
                          re.DOTALL)
    package = ""

    def get_data(self, match):
        self.result = self._get_text(match.group(2).rstrip())
        self.package = match.group(1)

    @property
    def log(self):
        return self.text_converter.transform(readFile(self.result))

    def action(self, child):
        raise EmergeError(_("Failed to emerge %s") % self.package)


class RevdepPercentBlock(NotifierInformationBlock):
    """
    Блок определния статуса revdep-rebuild
    """
    token = "Collecting system binaries"
    end_token = [re.compile("Assigning files to packages|"
                            "All prepared. Starting rebuild")]
    re_block = re.compile("\[\s(\d+)%\s\]")
    action = None

    def notify(self, observer, groups):
        percent = int(groups[0])
        observer(percent)

    def get_block(self, child):
        expect_result = [self.re_block]+self.end_token
        try:
            while True:
                index = child.expect(expect_result)
                if index == 0:
                    for observer in self.observers:
                        self.notify(observer, child.match.groups())
                else:
                    self.result = child.match
                    break
        except pexpect.EOF:
            self.result = ""

class EmergeParser(InfoBlockInterface):
    """
    Парсер вывода emerge
    """

    def __init__(self, command, run=False):
        self.command = command
        self.elements = {}

        self.install_packages = InstallPackagesBlock(self)
        self.uninstall_packages = UninstallPackagesBlock(self)
        self.question_group = QuestionGroup(self)
        self.change_config_question = QuestionChangeConfigBlock(
            self.question_group)
        self.question = QuestionBlock(self.question_group)
        self.finish_block = FinishEmergeGroup(self)
        self.need_root = NeedRootBlock(self)
        self.prepare_error = PrepareErrorBlock(self.finish_block)
        self.change_config_question.add_element(self.prepare_error)
        self.download_size = DownloadSizeBlock(self)
        self.skipped_packages = SkippedPackagesBlock(self)
        self.emerging_error = EmergeingErrorBlock(self)

        self.installing = InstallingPackage(self)
        self.uninstalling = UnemergingPackage(self)
        self.emerging = EmergingPackage(self)
        self.fetching = FetchingTarball(self)

        self.emerging.add_observer(self.mark_binary)
        self.emerging.add_observer(self.skip_fetching)
        if run:
            self.run()

    def mark_binary(self, package, binary=False, **kw):
        if binary:
            self.installing.mark_binary(package)

    def skip_fetching(self, *argv, **kw):
        self.fetching.action = lambda child: None

    def add_element(self, element):
        """
        :type element: InfoBlockInterface
        """
        if element.token:
            if type(element.token) == list:
                for token in element.token:
                    self.elements[token] = element
            else:
                self.elements[element.token] = element

    def run(self):
        """
        Запустить команду
        """
        child = self.command.execute()

        while True:
            index = child.expect_exact(self.elements.keys())
            element = self.elements.values()[index]
            element.get_block(child)
            if element.action:
                if element.action(child) is False:
                    break

    def close(self):
        self.command.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc_info):
        self.close()


class MtimeCheckvalue(object):
    def __init__(self, *fname):
        self.fname = fname

    def value_func(self, fn):
        return str(int(os.stat(fn).st_mtime))

    def get_check_values(self, file_list):
        for fn in file_list:
            if path.exists(fn) and not path.isdir(fn):
                yield fn, self.value_func(fn)
            else:
                for k, v in self.get_check_values(
                        listDirectory(fn, fullPath=True)):
                    yield k, v

    def checkvalues(self):
        return self.get_check_values(self.fname)


class Md5Checkvalue(MtimeCheckvalue):
    def value_func(self, fn):
        return hashlib.md5(readFile(fn)).hexdigest()


class GitCheckvalue(object):
    def __init__(self, git, rpath):
        self.rpath = rpath
        self.git = git

    def checkvalues(self):
        with ignore(GitError):
            if self.git.is_git(self.rpath):
                yield self.rpath, self.git.getCurrentCommit(self.rpath)


class EmergeCache(object):
    """
    Кэш пакетов
    """
    cache_file = '/var/lib/calculate/calculate-update/world.cache'
    # список файлов проверяемый по mtime на изменения
    check_list = [MtimeCheckvalue('/etc/make.conf',
                                  '/etc/portage',
                                  '/etc/make.profile'),
                  Md5Checkvalue('/var/lib/portage/world',
                                '/var/lib/portage/world_sets')]
    logger = log("emerge-cache",
                 filename="/var/log/calculate/emerge-cache.log",
                 formatter="%(asctime)s - %(levelname)s - %(message)s")

    def __init__(self):
        self.files_control_values = {}
        self.pkg_list = PackageList([])

    def set_cache(self, package_list):
        """
        Установить в кэш список пакетов
        """
        with writeFile(self.cache_file) as f:
            for fn, val in self.get_control_values().items():
                f.write("{fn}={val}\n".format(fn=fn, val=val))
            f.write('\n')
            for pkg in package_list:
                f.write("%s\n" % str(pkg))
        self.logger.info("Setting cache (%d packages)" % len(package_list))

    def drop_cache(self, reason=None):
        if path.exists(self.cache_file):
            with ignore(OSError):
                os.unlink(self.cache_file)
            self.logger.info("Droping cache. Reason: %s" % reason)
        else:
            self.logger.info("Droping empty cache. Reason: %s" % reason)

    def get_cached_package_list(self):
        self.read_cache()
        if not path.exists(self.cache_file):
            self.logger.info("Requesting empty cache")
        if self.check_actuality():
            return self.pkg_list
        return None

    def check_actuality(self):
        """
        Кэш считается актуальным если ни один из файлов не менялся
        """
        if self.get_control_values() == self.files_control_values:
            self.logger.info(
                "Getting actuality cache (%d packages)" % len(self.pkg_list))
            return True
        else:
            reason = "Unknown"
            for k, v in self.get_control_values().items():
                if k in self.files_control_values:
                    if v != self.files_control_values[k]:
                        reason = "%s was modified" % k
                else:
                    reason = "Checksum of file %s is not exist" % k
            self.logger.info("Failed to get cache. Reason: %s" % reason)
            return False

    def read_cache(self):
        self.files_control_values = {}
        cache_file_lines = readLinesFile(self.cache_file)
        for line in cache_file_lines:
            if "=" not in line:
                break
            k, v = line.split('=')
            self.files_control_values[k] = v.strip()
        self.pkg_list = PackageList(cache_file_lines)

    def get_control_values(self):
        def generate():
            for obj in self.check_list:
                for check_value in obj.checkvalues():
                    yield check_value

        return dict(generate())
