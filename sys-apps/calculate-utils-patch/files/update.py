# -*- coding: utf-8 -*-

# Copyright 2014-2016 Mir Calculate. http://www.calculate-linux.org
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
from functools import wraps
import random

import sys
reload(sys);
sys.setdefaultencoding('utf8')
from os import path
import os
import time
from calculate.core.server.gen_pid import search_worked_process
from calculate.core.setup_cache import Cache as SetupCache
from calculate.core.server.func import MethodsInterface
from calculate.lib.cl_template import SystemIni, LayeredIni
from calculate.lib.datavars import DataVarsError, VariableError, Variable

from calculate.lib.utils.tools import AddonError
from calculate.lib.utils.colortext.palette import TextState
from calculate.lib.utils.colortext import get_color_print
from calculate.update.emerge_parser import RevdepPercentBlock
from calculate.update.datavars import DataVarsUpdate
from calculate.update.update_info import UpdateInfo
from calculate.lib.utils.binhosts import (Binhosts, BinhostSignError,
    BinhostError, PackagesIndex, DAYS)
from calculate.lib.utils.gpg import GPG, GPGError
from calculate.lib.cl_log import log
import hashlib
import re
import shutil
from collections import MutableSet
from contextlib import contextmanager
import tempfile

from calculate.lib.utils.git import Git, GitError, MTimeKeeper, NotGitError
from calculate.lib.utils.portage import (Layman, EmergeLog,
                                         EmergeLogNamedTask,
                                         PackageInformation,
                                         get_packages_files_directory,
                                         get_manifest_files_directory,
                                         get_remove_list)
from calculate.lib.utils.text import _u8, _u

Colors = TextState.Colors
from calculate.lib.utils.files import (getProgPath, STDOUT, removeDir,
                                       PercentProgress, process, getRunCommands,
                                       readFile, listDirectory, pathJoin,
                                       find, FindFileType,quite_unlink,
                                       writeFile, makeDirectory)
import emerge_parser
import logging
from emerge_parser import (EmergeParser, EmergeCommand, EmergeError,
                           EmergeCache, Chroot)

from calculate.lib.cl_lang import (setLocalTranslate, getLazyLocalTranslate,
                                   RegexpLocalization, _)

setLocalTranslate('cl_update3', sys.modules[__name__])
__ = getLazyLocalTranslate(_)


class UpdateError(AddonError):
    """Update Error"""


class OverlayOwnCache(MutableSet):
    """
    Сет оверлеев с интегрированным кэшем
    """

    def __init__(self, dv=None):
        self.dv = dv

    def __get_overlays(self):
        own_cache_value = SystemIni(self.dv).getVar('system', 'own_cache') or ""
        return [x.strip() for x in own_cache_value.split(',') if x.strip()]

    def __write_overlays(self, overlays):
        if not overlays:
            SystemIni(self.dv).delVar('system', 'own_cache')
        else:
            SystemIni(self.dv).setVar('system',
                                      {'own_cache': ",".join(overlays)})

    def __contains__(self, item):
        return item in self.__get_overlays()

    def __iter__(self):
        return iter(self.__get_overlays())

    def __len__(self):
        return len(self.__get_overlays())

    def __append_value(self, overlays, value):
        if value not in overlays:
            overlays.append(value)
            self.__write_overlays(overlays)

    def add(self, value):
        overlays = self.__get_overlays()
        self.__append_value(overlays, value)

    def discard(self, value):
        overlays = self.__get_overlays()
        if value in overlays:
            overlays.remove(value)
            self.__write_overlays(overlays)


def variable_module(var_env):
    def variable_module_decor(f):
        @wraps(f)
        def wrapper(self, *args, **kw):
            old_env = self.clVars.defaultModule
            try:
                self.clVars.defaultModule = var_env
                return f(self, *args, **kw)
            finally:
                self.clVars.defaultModule = old_env

        return wrapper

    return variable_module_decor


class Update(MethodsInterface):
    """Основной объект для выполнения действий связанных с обновлением системы

    """

    def init(self):
        commandLog = path.join(self.clVars.Get('core.cl_log_path'),
                               'lastcommand.log')
        emerge_parser.CommandExecutor.logfile = commandLog
        self.color_print = get_color_print()
        self.emerge_cache = EmergeCache()
        if self.clVars.Get('cl_env_debug_set') == 'off':
            EmergeCache.logger.logger.setLevel(logging.WARNING)
        self.emerge_cache.check_list = (
            self.emerge_cache.check_list +
            map(lambda x:emerge_parser.GitCheckvalue(x, self.getGit()),
                self.clVars.Get('update.cl_update_rep_path')))
        self.update_map = {}
        self.refresh_binhost = False
        self.pkgnum = None
        self.pkgnummax = None
        self.gpgdata_md5 = []
        self.gpg_changed = False

    def get_prog_path(self, program_name):
        return getProgPath(program_name)

    def getGit(self):
        return self.clVars.Get('cl_update_git')

    @contextmanager
    def private_repo(self, rpath, url):
        if Git.is_private_url(url):
            try:
                if not path.exists(rpath):
                    makeDirectory(rpath)
                os.chmod(rpath, 0700)
                yield
            finally:
                try:
                    for dn in (Git._gitDir(rpath), path.join(rpath, "profiles/templates")):
                        if path.exists(dn):
                            os.chmod(dn, 0700)
                    for fn in find(path.join(rpath, "profiles"), True, FindFileType.RegularFile,
                                   True, None, downfilter=lambda x: not x.endswith("/templates")):
                        if fn.endswith("calculate.env") or fn.endswith("ini.env"):
                            os.chmod(fn, 0600)
                    if path.exists(rpath):
                        os.chmod(rpath, 0755)
                except OSError:
                    pass
        else:
            yield

    def _syncRepository(self, name, url, rpath, revision,
                        cb_progress=None, clean=False, notask=False):
        """
        Синхронизировать репозитори
        """
        dv = self.clVars
        git = self.getGit()
        info_outdated = False
        old_dir = "%s.old" % git._gitDir(rpath)
        if path.exists(old_dir):
            clean = True
        try:
            self.stash_cache(rpath, name)
            if not git.checkExistsRep(rpath):
                if not notask:
                    self.startTask(_("Syncing the {rep} repository").format(
                        rep=name.capitalize()))
                self.addProgress()
                with self.private_repo(rpath, url):
                    git.cloneTagRepository(url, rpath, revision,
                                           cb_progress=cb_progress)
                info_outdated = True
            else:
                cr = ""
                try:
                    need_update = False
                    tag_cr = git.getCommit(rpath, revision)
                    cr = git.getCurrentCommit(rpath)
                    ref_type = git.reference_type(rpath, revision)
                    if tag_cr != cr or ref_type == Git.Reference.Branch:
                        need_update = True
                    elif clean:
                        status = git.getStatusInfo(rpath)
                        if not status or status['files']:
                            need_update = True
                except GitError as e:
                    need_update = True
                if need_update:
                    if not notask:
                        self.startTask(_("Syncing the {rep} repository").format(
                            rep=name.capitalize()))
                    self.addProgress()
                    with self.private_repo(rpath, url):
                        git.updateTagRepository(url, rpath, revision,
                                                cb_progress=cb_progress,
                                                clean=clean)
                    new_cr = git.getCurrentCommit(rpath)
                    if new_cr != cr:
                        info_outdated = True
            if info_outdated:
                self.raiseOutdate()
                dv.Set('cl_update_outdate_set', 'on', force=True)
        finally:
            self.unstash_cache(rpath, name)
        # TODO: debug1
        #dv.Set('cl_update_outdate_set', 'on', force=True)
        return True

    def raiseOutdate(self):
        self.clVars.Set('cl_update_outdate_set', 'on', force=True)

    def setAutocheckParams(self, status, interval, update_other, cleanpkg):
        """
        Настроить параметры автопроверки обновлений
        """
        onoff = lambda x: "on" if x else "off"
        self.clVars.Write('cl_update_autocheck_set', onoff(status), True)
        self.clVars.Write('cl_update_autocheck_interval', interval, True)
        self.clVars.Write('cl_update_other_set', onoff(update_other), True)
        self.clVars.Write('cl_update_cleanpkg_set', onoff(cleanpkg), True)
        if not status:
            UpdateInfo.set_update_ready(False)
        return True

    def checkSchedule(self, interval, status):
        """
        Проверить по расписанию необходимость запуска команды
        """
        if not status:
            self.printWARNING(_("Updates autocheck is not enabled"))
            return False
        last_check = SystemIni(self.clVars).getVar('system', 'last_check') or ""
        re_interval = re.compile("^(\d+)\s*(hours?|days?|weeks?)?", re.I)
        interval_match = re_interval.search(interval)
        MINUTE = 60
        HOUR = MINUTE * 60
        DAY = HOUR * 24
        WEEK = DAY * 7
        if interval_match:
            if interval_match.group(2):
                suffix_map = {'h': HOUR, 'd': DAY, 'w': WEEK}
                k = suffix_map.get(interval_match.group(2).lower()[0], HOUR)
            else:
                k = HOUR
            est = int(interval_match.group(1)) * k
        else:
            est = 3 * HOUR
        if last_check:
            if last_check.isdigit():
                if (time.time() - int(last_check)) < (est - 10 * MINUTE):
                    self.printWARNING(_("Please wait for the update time"))
                    return False
        self.mark_schedule()
        return True

    def checkRun(self, wait_update):
        """
        Проверить повторный запуск
        """
        update_running = lambda: any(os.getpid() != x
                                     for x in
                                     search_worked_process('update', dv))
        dv = self.clVars
        if update_running():
            if not wait_update:
                raise UpdateError(_("Update is already running. "
                                    "Try to run later."))
            else:
                self.startTask(_("Waiting for another update to be complete"))

                while update_running():
                    self.pauseProcess()
                    while update_running():
                        time.sleep(0.3)
                    self.resumeProcess()
                    time.sleep(random.random() * 3)
                self.endTask()

        if self.clVars.Get('cl_chroot_status') == 'off':
            emerge_running = lambda: any("/usr/bin/emerge" in x
                                         for x in getRunCommands(True))
            if emerge_running():
                if not wait_update:
                    raise UpdateError(_("Emerge is running. "
                                        "Try to run later."))
                else:
                    self.startTask(_("Waiting for emerge to be complete"))
                    while emerge_running():
                        time.sleep(1)
                    self.endTask()
        return True

    @variable_module("update")
    def trimRepositories(self, repname):
        """
        Синхронизировать репозитории
        """
        dv = self.clVars
        rpath = \
            dv.select('cl_update_rep_path', cl_update_rep_name=repname, limit=1)
        git = self.getGit()
        self.addProgress()
        git.trimRepository(rpath, cb_progress=self.setProgress)
        return True

    @variable_module("update")
    def syncRepositories(self, repname, fallback_sync=False,
                         clean_on_error=True):
        """
        Синхронизировать репозитории
        """
        dv = self.clVars
        check_status = dv.GetBool('update.cl_update_check_rep_set')
        url, rpath, revision = (
            dv.Select(["cl_update_rep_url", "cl_update_rep_path",
                       "cl_update_rep_rev"],
                      where="cl_update_rep_name", eq=repname, limit=1))
        if not url or not rpath:
            raise UpdateError(_("Configuration variables for repositories "
                                "are not setup"))
        git = self.getGit()
        if not git.checkUrl(url):
            raise UpdateError(_("Git %s is unavailable") % url)
        chroot_path = path.normpath(self.clVars.Get('cl_chroot_path'))
        if chroot_path == '/':
            rpath_orig = rpath
        else:
            rpath_orig = rpath[len(chroot_path):]

        mtime = MTimeKeeper(path.join(rpath, "profiles/updates"))
        mtime.save()
        try:
            if clean_on_error:
                try:
                    layman = Layman(dv.Get('cl_update_layman_installed'),
                                    dv.Get('cl_update_layman_make'),
                                    dv.Get('cl_update_layman_conf'),
                                    prefix=chroot_path)
                    if repname not in ("portage", "gentoo"):
                        layman.add(repname, url, rpath_orig)
                    if not self._syncRepository(repname, url, rpath, revision,
                                                cb_progress=self.setProgress,
                                                clean=check_status,
                                                notask=fallback_sync):
                        return "skip"
                    return True
                except GitError as e:
                    if not isinstance(e, NotGitError):
                        if e.addon:
                            self.printWARNING(str(e.addon))
                        self.printWARNING(str(e))
                        self.endTask(False)
                        self.startTask(
                            _("Re-fetching the {name} repository").format(
                                name=repname))
                        self.addProgress()
                    rpath_new = "%s_new" % rpath
                    try:
                        self._syncRepository(repname, url, rpath_new, revision,
                                             cb_progress=self.setProgress,
                                             clean=check_status,
                                             notask=fallback_sync)
                        removeDir(rpath)
                        shutil.move(rpath_new, rpath)
                    except OSError as e:
                        raise UpdateError(_("Failed to modify the "
                                            "{repname} repository").format(
                            repname=repname) + _(": ") + str(e))
                    finally:
                        if path.exists(rpath_new):
                            removeDir(rpath_new)
            else:
                if not self._syncRepository(repname, url, rpath, revision,
                                            clean=check_status):
                    return "skip"

            layman = Layman(dv.Get('cl_update_layman_installed'),
                            dv.Get('cl_update_layman_make'),
                            dv.Get('cl_update_layman_conf'),
                            prefix=chroot_path)
            if repname not in ("portage", "gentoo"):
                layman.add(repname, url, rpath_orig)
        finally:
            mtime.restore()
        return True

    metadata_cache_names = ("metadata/md5-cache", "metadata/cache")

    def stash_cache(self, rpath, name):
        """
        Спрятать кэш
        """
        if name in ("portage", "gentoo"):
            return
        if not name in OverlayOwnCache(self.clVars):
            for cachename in self.metadata_cache_names:
                cachedir = path.join(rpath, cachename)
                if path.exists(cachedir):
                    try:
                        cachedir_s = path.join(path.dirname(rpath),
                                               path.basename(
                                                   cachename) + ".stash")
                        if path.exists(cachedir_s):
                            removeDir(cachedir_s)
                        shutil.move(cachedir, cachedir_s)
                    except BaseException as e:
                        pass

    def unstash_cache(self, rpath, name):
        """
        Извлеч кэш
        """
        if name in ("portage", "gentoo"):
            return
        cachenames = self.metadata_cache_names
        if not name in OverlayOwnCache(self.clVars):
            if any(path.exists(path.join(rpath, x)) for x in cachenames):
                for cachename in cachenames:
                    cachedir_s = path.join(path.dirname(rpath),
                                           path.basename(cachename) + ".stash")
                    if path.exists(cachedir_s):
                        try:
                            removeDir(cachedir_s)
                        except BaseException as e:
                            pass
                OverlayOwnCache(self.clVars).add(name)
            else:
                for cachename in cachenames:
                    cachedir = path.join(rpath, cachename)
                    cachedir_s = path.join(path.dirname(rpath),
                                           path.basename(cachename) + ".stash")
                    if path.exists(cachedir_s):
                        try:
                            shutil.move(cachedir_s, cachedir)
                        except BaseException as e:
                            pass
        else:
            if all(not path.exists(path.join(rpath, x)) for x in cachenames):
                OverlayOwnCache(self.clVars).discard(name)

    def syncLaymanRepository(self, repname):
        """
        Обновить репозиторий через layman
        """
        layman = self.get_prog_path('/usr/bin/layman')
        if not layman:
            raise UpdateError(_("The Layman tool is not found"))

        rpath = self.clVars.Select('cl_update_other_rep_path',
                                   where='cl_update_other_rep_name', eq=repname,
                                   limit=1)
        laymanname = path.basename(rpath)
        self.stash_cache(rpath, laymanname)
        try:
            if Git.is_git(rpath):
                self.addProgress()
                p = PercentProgress(layman, "-s", laymanname, part=1, atty=True)
                for perc in p.progress():
                    self.setProgress(perc)
            else:
                p = process(layman, "-s", repname, stderr=STDOUT)
            if p.failed():
                raise UpdateError(
                    _("Failed to update the {rname} repository").format(
                        rname=repname),
                    addon=p.read())
        finally:
            self.unstash_cache(rpath, laymanname)
        return True

    def _regenCache_process(self, progname, repname, cpu_num):
        return process(progname, "--repo=%s" % repname, "--update",
                       "--jobs=%s" % cpu_num, stderr=STDOUT)

    def regenCache(self, repname):
        """
        Обновить кэш метаданных репозитория
        """
        egenCache = self.get_prog_path('/usr/bin/egencache')
        if not egenCache:
            raise UpdateError(_("The Portage tool is not found"))
        if repname in self.clVars.Get('cl_update_rep_name'):
            path_rep = self.clVars.Select('cl_update_rep_path',
                                          where='cl_update_rep_name',
                                          eq=repname, limit=1)
            repo_name = readFile(
                path.join(path_rep, "profiles/repo_name")).strip()
            if repo_name != repname:
                self.printWARNING(
                    _("Repository '{repo_name}' called '{repname}'"
                      " in cl_update_rep_name").format(
                        repo_name=repo_name, repname=repname))
                raise UpdateError(_("Failed to update the cache of the {rname} "
                                    "repository").format(rname=repname))
        cpu_num = self.clVars.Get('hr_cpu_num')
        if repname in OverlayOwnCache(self.clVars):
            self.printWARNING(
                _("Repository %s has its own cache") % repname.capitalize())
        else:
            self.startTask(_("Updating the %s repository cache") %
                           repname.capitalize())
            p = self._regenCache_process(egenCache, repname, cpu_num)
            if p.failed():
                raise UpdateError(_("Failed to update the cache of the {rname} "
                                    "repository").format(rname=repname),
                                  addon=p.read())
        return True

    def emergeMetadata(self):
        """
        Выполнить egencache и emerge --metadata
        """
        emerge = self.get_prog_path("/usr/bin/emerge")
        if not emerge:
            raise UpdateError(_("The Emerge tool is not found"))
        self.addProgress()
        p = PercentProgress(emerge, "--ask=n", "--metadata", part=1, atty=True)
        for perc in p.progress():
            self.setProgress(perc)
        if p.failed():
            data = p.read()
            with open('/var/log/calculate/failed-metadata-%d.log' % time.time(),
                      'w') as f:
                f.write(data + p.alldata)
            raise UpdateError(_("Failed to update metadata"), addon=data)
        return True

    def _eixUpdateCommand(self, eix_cmd, countRep):
        return PercentProgress(eix_cmd, "-F", part=countRep or 1, atty=True)

    def eixUpdate(self, repositroies):
        """
        Выполенине eix-update для репозиторием

        eix-update выполнятется только для тех репозиториев, которые
        обновлялись, если cl_update_eixsync_force==auto, либо
        все, если cl_update_eixupdate_force==force
        """
        eixupdate = self.get_prog_path("/usr/bin/eix-update")
        if not eixupdate:
            raise UpdateError(_("The Eix tool is not found"))
        self.addProgress()
        countRep = len(repositroies)
        p = self._eixUpdateCommand(eixupdate, countRep)
        for perc in p.progress():
            self.setProgress(perc)
        if p.failed():
            raise UpdateError(_("Failed to update eix cache"), addon=p.read())
        return True

    def is_binary_pkg(self, pkg, binary=None):
        """
        Является ли пакет бинарным
        """
        if binary:
            return True
        if 'PN' in pkg and pkg['PN'].endswith('-bin'):
            return True
        if binary is not None:
            return binary
        if "binary" in pkg and pkg['binary']:
            return True
        return False

    def _printEmergePackage(self, pkg, binary=False, num=1, max_num=1):
        """
        Вывод сообщения сборки пакета
        """
        self.endTask()
        _print = self.color_print
        if self.pkgnum is not None:
            num = self.pkgnum
        if self.pkgnummax is not None:
            max_num = self.pkgnummax
        one = _print("{0}", num)
        two = _print("{0}", max_num)
        part = _("({current} of {maximum})").format(current=one, maximum=two)
        _print = _print.foreground(Colors.DEFAULT)
        if self.is_binary_pkg(pkg, binary):
            _colorprint = _print.foreground(Colors.PURPLE)
        else:
            _colorprint = _print.foreground(Colors.GREEN)

        PackageInformation.add_info(pkg)
        name = ""
        if pkg.info['DESCRIPTION']:
            name = _(pkg.info['DESCRIPTION'])
            name = name[:1].upper() + name[1:]
        if not name.strip():
            name = str(pkg)

        self.printSUCCESS(
            _u(_("{part} {package}")).format(part=_u(part), package=_u(name)))
        self.startTask(
            _u(_("Emerging {package}")).format(package=_u(_colorprint(str(pkg)))))

    def _printInstallPackage(self, pkg, binary=False):
        """
        Вывод сообщения установки пакета
        """
        self.endTask()
        _print = self.color_print
        if self.is_binary_pkg(pkg, binary):
            _print = _print.foreground(Colors.PURPLE)
        else:
            _print = _print.foreground(Colors.GREEN)
        pkg_key = "{CATEGORY}/{PF}".format(**pkg)
        if pkg_key in self.update_map:
            self.startTask(_("Installing {pkg} [{oldver}]").format(
                pkg=_print(str(pkg)), oldver=self.update_map[pkg_key]))
            self.update_map.pop(pkg_key)
        else:
            self.startTask(_("Installing %s") % (_print(str(pkg))))

    def _printFetching(self, fn):
        """
        Вывод сообщения о скачивании
        """
        self.endTask()
        self.startTask(_("Fetching binary packages"))

    def _printUninstallPackage(self, pkg, num=1, max_num=1):
        """
        Вывод сообщения удаления пакета
        """
        self.endTask()
        _print = self.color_print
        if num and max_num:
            one = _print("{0}", num)
            two = _print("{0}", max_num)
            part = _(" ({current} of {maximum})").format(current=one,
                                                         maximum=two)
        else:
            part = ""
        _print = _print.foreground(Colors.LIGHT_RED)

        self.startTask(
            _("Unmerging{part} {package}").format(part=part,
                                                  package=_print(str(pkg))))

    def emergelike(self, cmd, *params):
        """
        Запуск команды, которая подразумевает выполнение emerge
        """
        cmd_path = self.get_prog_path(cmd)
        if not cmd_path:
            raise UpdateError(_("Failed to find the %s command") % cmd)
        with EmergeParser(
                emerge_parser.CommandExecutor(cmd_path, params)) as emerge:
            self._startEmerging(emerge)
        return True

    def revdep_rebuild(self, cmd, *params):
        """
        Запуск revdep-rebulid
        """
        cmd_path = self.get_prog_path(cmd)
        if not cmd_path:
            raise UpdateError(_("Failed to find the %s command") % cmd)
        with EmergeParser(
                emerge_parser.CommandExecutor(cmd_path, params)) as emerge:
            revdep = RevdepPercentBlock(emerge)
            self.addProgress()
            revdep.add_observer(self.setProgress)
            revdep.action = lambda x: (
                self.endTask(), self.startTask(_("Assigning files to packages"))
                if "Assign" in revdep else None)
            self._startEmerging(emerge)
        return True

    def _display_pretty_package_list(self, pkglist, remove_list=False):
        """
        Отобразить список пакетов в "удобочитаемом" виде
        """
        _print = self.color_print
        ebuild_color = TextState.Colors.GREEN
        binary_color = TextState.Colors.PURPLE
        remove_color = TextState.Colors.LIGHT_RED
        flag_map = {"updating":
                        _print.foreground(TextState.Colors.LIGHT_CYAN)("U"),
                    "reinstall":
                        _print.foreground(TextState.Colors.YELLOW)("rR"),
                    "new":
                        _print.foreground(TextState.Colors.LIGHT_GREEN)("N"),
                    "newslot":
                        _print.foreground(TextState.Colors.LIGHT_GREEN)("NS"),
                    "downgrading": (
                        _print.foreground(TextState.Colors.LIGHT_CYAN)("U") +
                        _print.foreground(TextState.Colors.LIGHT_BLUE)("D"))}
        for pkg in sorted([PackageInformation.add_info(x) for x in
                           pkglist],
                          key=lambda y: y['CATEGORY/PN']):
            install_flag = ""
            if remove_list:
                pkgcolor = _print.foreground(remove_color)
            else:
                for flag in flag_map:
                    if pkg[flag]:
                        install_flag = "(%s) " % flag_map[flag]
                        break
                if self.is_binary_pkg(pkg):
                    pkgcolor = _print.foreground(binary_color)
                else:
                    pkgcolor = _print.foreground(ebuild_color)

            if pkg.info['DESCRIPTION']:
                fullname = "%s " % _(pkg.info['DESCRIPTION'])
                fullname = fullname[:1].upper() + fullname[1:]
            else:
                fullname = ""
            shortname = pkgcolor("%s-%s" % (pkg["CATEGORY/PN"], pkg["PVR"]))
            if "SIZE" in pkg and pkg['SIZE'] and pkg["SIZE"] != "0 kB":
                size = " (%s)" % pkg["SIZE"]
            else:
                size = ""
            mult = _print.bold("*")
            self.printDefault(
                _u8("&nbsp;{mult} {fullname}{flag}{shortname}{size}").format(
                    mult=_u8(mult), fullname=_u8(fullname), shortname=_u8(shortname),
                    size=_u8(size),
                    flag=_u8(install_flag)))

    def _display_install_package(self, emerge, emergelike=False):
        """
        Отобразить список устанавливаемых пакетов
        """
        # подробный список пакетов
        _print = self.color_print
        if emergelike:
            self.printPre(str(emerge.install_packages))
        else:
            pkglist = emerge.install_packages.list
            self.printSUCCESS(_print(
                _("Listing packages for installation")))
            self._display_pretty_package_list(pkglist)
            if emerge.install_packages.remove_list:
                self.printSUCCESS(_print(
                    _("Listing packages for removal")))
                self._display_pretty_package_list(
                    emerge.install_packages.remove_list, remove_list=True)
        if len(emerge.install_packages.list) > 0:
            install_mess = (_("{count} packages will be installed").format(
                count=len(emerge.install_packages.list)) + ", ")
        else:
            install_mess = ""
        if str(emerge.download_size) != "0 kB":
            self.printSUCCESS(_("{install}{size} will be downloaded").format(
                install=install_mess,
                size=str(emerge.download_size)))

    def _display_remove_list(self, emerge):
        """
        Отобразить список удаляемых пакетов
        """
        # подробный список пакетов
        if self.clVars.Get('update.cl_update_emergelist_set') == 'on':
            self.printPre(self._emerge_translate(
                emerge.uninstall_packages.verbose_result))
        else:
            _print = self.color_print
            pkglist = emerge.uninstall_packages.list
            self.printSUCCESS(_print.bold(
                _("Listing packages for removal")))
            self._display_pretty_package_list(pkglist, remove_list=True)

    def mark_schedule(self):
        """
        Установить отметку о запуске запланированной проверки
        """
        SystemIni(self.clVars).setVar('system', {'last_check': str(int(time.time()))})

    def get_default_emerge_opts(self, depclean=False):
        if depclean and self.clVars.GetBool('cl_update_with_bdeps_set'):
            bdeps = " --with-bdeps=y"
        else:
            bdeps = " --with-bdeps=n"
        return self.clVars.Get('cl_emerge_default_opts') + bdeps

    def premerge(self, param, *packages):
        """
        Вывести информацию об обновлении
        """
        deo = self.get_default_emerge_opts()
        param = [param, "-pv"]

        with EmergeParser(EmergeCommand(list(packages), emerge_default_opts=deo,
                                        extra_params=param)) as emerge:
            try:
                emerge.run()
                if not emerge.install_packages.list:
                    self.printSUCCESS(_("The system is up to date"))
                    self.set_need_update(False)
                    return True
                emergelike = self.clVars.Get('cl_update_emergelist_set') == 'on'
                self._display_install_package(emerge, emergelike)
                if str(emerge.skipped_packages):
                    self._display_error(emerge.skipped_packages)
            except EmergeError:
                self.set_need_update(False)
                self._display_install_package(emerge, emergelike=True)
                self._display_error(emerge.prepare_error)
                raise
            if self.clVars.Get('cl_update_pretend_set') == 'on':
                # установить кэш: есть обновления
                self.set_need_update()
                return True
            self.set_need_update(False)
            answer = self.askConfirm(
                _("Would you like to merge these packages?"), "yes")
            if answer == "no":
                raise KeyboardInterrupt
            return "yes"
        return True

    def set_need_update(self, val=True):
        """
        Установить флаг: есть обновления
        """
        if self.clVars.Get('update.cl_update_autocheck_set') == 'off':
            val = False
        UpdateInfo.set_update_ready(val)
        return True

    def _emerge_translate(self, s):
        """
        Перевести текст из emerge
        """
        return RegexpLocalization('cl_emerge').translate(str(s))

    def setUpToDateCache(self):
        """
        Установить кэш - "нет пакетов для обновления"
        """
        #self.updateCache(PackageList([]))
        self.set_need_update(False)
        return True

    def _startEmerging(self, emerge):
        """
        Настроить и выполнить emerge
        """
        if emerge.install_packages and emerge.install_packages.list:
            for pkg in emerge.install_packages.list:
                rv = pkg.get('REPLACING_VERSIONS', '')
                if rv:
                    self.update_map["{CATEGORY}/{PF}".format(**pkg)] = \
                        rv.partition(":")[0]
        emerge.command.send("yes\n")
        emerge.emerging.add_observer(self._printEmergePackage)
        emerge.installing.add_observer(self._printInstallPackage)
        emerge.uninstalling.add_observer(self._printUninstallPackage)
        emerge.fetching.add_observer(self._printFetching)

        def cancel_observing_fetch(fn):
            emerge.fetching.clear_observers()

        emerge.fetching.add_observer(cancel_observing_fetch)
        try:
            emerge.run()
        except EmergeError:
            if emerge.emerging_error:
                self._display_error(emerge.emerging_error.log)
            else:
                self._display_error(emerge.prepare_error)
            raise

    def _display_error(self, error):
        lines_num = int(self.clVars.Get('update.cl_update_lines_limit'))
        error = "<br/>".join(str(error).split('<br/>')[-lines_num:])
        self.printPre(self._emerge_translate(error))

    def emerge(self, use, param, *packages):
        """
        Выполнить сборку пакета
        """
        deo = self.get_default_emerge_opts()
        if not packages:
            packages = [param]
            extra_params = None
        else:
            extra_params = [param]

        command = EmergeCommand(list(packages), emerge_default_opts=deo,
                                extra_params=extra_params,
                                use=use)
        if self.clVars.Get('cl_chroot_path') != '/':
            command = Chroot(self.clVars.Get('cl_chroot_path'), command)

        with EmergeParser(command) as emerge:
            try:
                emerge.question.action = lambda x: False
                emerge.run()
                if not emerge.install_packages.list:
                    return True
            except EmergeError:
                self._display_error(emerge.prepare_error)
                raise
            self._startEmerging(emerge)
        return True

    def emerge_ask(self, pretend, *params):
        """
        Вывести информацию об обновлении
        """
        deo = self.get_default_emerge_opts()
        param = [x for x in params if x.startswith("-")]
        packages = [x for x in params if not x.startswith("-")]
        command = EmergeCommand(list(packages), emerge_default_opts=deo,
                                extra_params=param)
        with EmergeParser(command) as emerge:
            try:
                emerge.question.action = lambda x: False
                emerge.run()
                if emerge.install_packages.list:
                    emergelike = self.clVars.Get(
                        'update.cl_update_emergelist_set') == 'on'
                    self._display_install_package(emerge, emergelike)
                    if emerge.skipped_packages:
                        self._display_error(emerge.skipped_packages)
                    if not pretend:
                        answer = self.askConfirm(
                            _("Would you like to merge these packages?"), "yes")
                        if answer == "no":
                            emerge.command.send("no\n")
                            raise KeyboardInterrupt
                    else:
                        return True
                else:
                    self.set_need_update(False)
                    self.printSUCCESS(_("The system is up to date"))
            except EmergeError:
                self.set_need_update(False)
                self._display_install_package(emerge, emergelike=True)
                self._display_error(emerge.prepare_error)
                raise
            self._startEmerging(emerge)
        return True

    def depclean(self):
        """
        Выполнить очистку системы от лишних пакетов
        """
        deo = self.get_default_emerge_opts(depclean=True)
        emerge = None
        try:
            emerge = EmergeParser(EmergeCommand(["--depclean"],
                                                emerge_default_opts=deo))
            outdated_kernel = False
            try:
                emerge.question.action = lambda x: False
                emerge.run()
                if not emerge.uninstall_packages.list:
                    UpdateInfo(self.clVars).outdated_kernel = False
                    return True
                kernel_pkg = self.clVars.Get('cl_update_kernel_pkg')
                if any(("%s-%s" % (x['CATEGORY/PN'], x['PVR'])) == kernel_pkg
                       for x in emerge.uninstall_packages.list):
                    pkglist = [
                        "=%s-%s" % (x['CATEGORY/PN'], x['PVR']) for x in
                        emerge.uninstall_packages.list
                        if ("%s-%s" % (x['CATEGORY/PN'],
                                       x['PVR'])) != kernel_pkg]
                    emerge.command.send('n\n')
                    emerge.close()
                    emerge = None
                    if not pkglist:
                        UpdateInfo(self.clVars).outdated_kernel = True
                        return True
                    emerge = EmergeParser(
                        EmergeCommand(pkglist,
                                      extra_params=["--unmerge", '--ask=y'],
                                      emerge_default_opts=deo))
                    emerge.question.action = lambda x: False
                    emerge.run()
                    outdated_kernel = True
                else:
                    outdated_kernel = False
                self._display_remove_list(emerge)
            except EmergeError:
                self._display_error(emerge.prepare_error)
                raise
            if (self.askConfirm(
                    _("Would you like to unmerge these unused packages "
                      "(recommended)?")) != 'yes'):
                return True
            UpdateInfo(self.clVars).outdated_kernel = outdated_kernel
            self._startEmerging(emerge)
        finally:
            if emerge:
                emerge.close()
        return True

    def update_task(self, task_name):
        """
        Декоратор для добавления меток запуска и останова задачи
        """

        def decor(f):
            def wrapper(*args, **kwargs):
                logger = EmergeLog(EmergeLogNamedTask(task_name))
                logger.mark_begin_task()
                ret = f(*args, **kwargs)
                if ret:
                    logger.mark_end_task()
                return ret

            return wrapper

        return decor

    def migrateCacheRepository(self, url, branch, storage):
        """
        Перенести репозиторий из кэша в локальный
        """
        rep = storage.get_repository(url, branch)
        if rep:
            rep.storage = storage.storages[0]
            self.clVars.Invalidate('cl_update_profile_storage')
        return True

    def reconfigureProfileVars(self, profile_dv, chroot):
        """
        Синхронизировать репозитории
        Настройка переменных для выполнения синхронизации репозиториев
        """
        dv = self.clVars

        try:
            if not profile_dv:
                raise UpdateError(
                    _("Failed to use the new profile. Try again."))
            for var_name in ('cl_update_rep_path',
                             'cl_update_rep_url',
                             'cl_update_rep_name',
                             'cl_update_branch',
                             'cl_update_binhost_list',
                             'cl_update_binhost_unstable_list',
                             'cl_update_binhost_stable_set',
                             'cl_update_binhost_stable_opt_set',
                             'cl_update_branch_name',
                             'cl_profile_system',
                             'cl_update_rep'):
                dv.Set(var_name, profile_dv.Get(var_name), force=True)
            dv.Set('cl_chroot_path', chroot, force=True)
        except DataVarsError as e:
            error = UpdateError(_("Wrong profile"))
            error.addon = e
            raise error
        return True

    def setProfile(self, profile_shortname):
        profile = self.clVars.Select('cl_update_profile_path',
                                     where='cl_update_profile_shortname',
                                     eq=profile_shortname, limit=1)
        if not profile:
            raise UpdateError(_("Failed to determine profile %s") %
                              self.clVars.Get('cl_update_profile_system'))
        profile_path = path.relpath(profile, '/etc/portage')
        try:
            profile_file = '/etc/portage/make.profile'
            if not path.exists(
                    path.join(path.dirname(profile_file), profile_path)):
                raise UpdateError(
                    _("Failed to set the profile: %s") % _("Profile not found"))
            for rm_fn in filter(path.lexists,
                                ('/etc/make.profile',
                                 '/etc/portage/make.profile')):
                os.unlink(rm_fn)
            os.symlink(profile_path, profile_file)
        except (OSError, IOError) as e:
            raise UpdateError(_("Failed to set the profile: %s") % str(e))
        return True

    def applyProfileTemplates(self, useClt=None, cltFilter=False,
                              useDispatch=True, action="merge"):
        """
        Наложить шаблоны из профиля
        """
        from calculate.lib.cl_template import TemplatesError, ProgressTemplate

        dv = DataVarsUpdate()
        try:
            dv.importUpdate()
            dv.flIniFile()
            dv.Set('cl_action', action, force=True)
            try:
                dv.Set('cl_templates_locate',
                       self.clVars.Get('cl_update_templates_locate'))
            except VariableError:
                self.printERROR(_("Failed to apply profiles templates"))
                return True
            dv.Set("cl_chroot_path", '/', True)
            dv.Set("cl_root_path", '/', True)
            for copyvar in ("cl_dispatch_conf", "cl_verbose_set",
                            "update.cl_update_world"):
                dv.Set(copyvar, self.clVars.Get(copyvar), True)
            # определение каталогов содержащих шаблоны
            useClt = useClt in ("on", True)
            self.addProgress()
            nullProgress = lambda *args, **kw: None
            dispatch = self.dispatchConf if useDispatch else None
            clTempl = ProgressTemplate(nullProgress, dv, cltObj=useClt,
                                       cltFilter=cltFilter,
                                       printSUCCESS=self.printSUCCESS,
                                       printWARNING=self.printWARNING,
                                       askConfirm=self.askConfirm,
                                       dispatchConf=dispatch,
                                       printERROR=self.printERROR)
            try:
                clTempl.applyTemplates()
                if clTempl.hasError():
                    if clTempl.getError():
                        raise TemplatesError(clTempl.getError())
            finally:
                if clTempl:
                    if clTempl.cltObj:
                        clTempl.cltObj.closeFiles()
                    clTempl.closeFiles()
        finally:
            dv.close()
        return True

    def cleanpkg(self):
        """
        Очистить PKGDIR и DISTFILES в текущей системе
        """
        portdirs = ([self.clVars.Get('cl_portdir')] +
                    self.clVars.Get('cl_portdir_overlay'))
        pkgfiles = get_packages_files_directory(*portdirs)
        distdirfiles = get_manifest_files_directory(*portdirs)
        distdir = self.clVars.Get('install.cl_distfiles_path')
        pkgdir = self.clVars.Get('cl_pkgdir')

        logger = log("update_cleanpkg.log",
                     filename="/var/log/calculate/update_cleanpkg.log",
                     formatter="%(asctime)s - %(clean)s - %(message)s")

        return self._cleanpkg(
            distdir, pkgdir, distdirfiles, pkgfiles, logger)

    def _update_binhost_packages(self):
        os.system('/usr/sbin/emaint binhost -f &>/dev/null')

    def _cleanpkg(self, distdir, pkgdir, distdirfiles, pkgfiles, logger):
        """
        Общий алгоритм очистки distfiles и pkgdir от устаревших пакетов
        """
        skip_files = ["/metadata.dtd", "/Packages"]
        try:
            if self.clVars.Get('client.os_remote_auth'):
                skip_files += ['portage_lockfile']
        except DataVarsError:
            pass

        for cleantype, filelist in (
                ("packages",
                 get_remove_list(pkgdir, list(pkgfiles), depth=4)),
                ("distfiles",
                 get_remove_list(distdir, list(distdirfiles), depth=1))):
            removelist = []
            for fn in filelist:
                try:
                    if not any(fn.endswith(x) for x in skip_files):
                        os.unlink(fn)
                        removelist.append(path.basename(fn))
                except OSError:
                    pass
            removelist_str = ",".join(removelist)
            if removelist_str:
                logger.info(removelist_str, extra={'clean': cleantype})
                if cleantype == "packages":
                    try:
                        self._update_binhost_packages()
                        for dn in listDirectory(pkgdir, fullPath=True):
                            if path.isdir(dn) and not listDirectory(dn):
                                os.rmdir(dn)
                    except OSError:
                        pass
        return True

    def updateSetupCache(self):
        cache = SetupCache(self.clVars)
        cache.update(force=True)
        return True

    def get_bin_cache_filename(self):
        return pathJoin(self.clVars.Get('cl_chroot_path'),
                        LayeredIni.IniPath.Grp)

    def update_local_info_binhost(self, write_binhost=True):
        """
        Проверить, что доступен хотя бы один из binhost'ов
        :return:
        """
        hosts = self.clVars.Get("update.cl_update_binhost_host")
        datas = self.clVars.Get("update.cl_update_binhost_revisions")
        if not hosts:
            self.delete_binhost()
            raise UpdateError(_("Failed to find the server with "
                                "appropriate updates"))
        else:
            with writeFile(self.get_bin_cache_filename()) as f:
                f.write(datas[0].strip()+"\n")
        if write_binhost:
            if hosts[0] != self.clVars.Get('update.cl_update_binhost'):
                self.refresh_binhost = True
                self.clVars.Set('cl_update_package_cache_set', 'on')
            self.clVars.Write('cl_update_binhost', hosts[0], location="system")
            new_ts = self.clVars.Get("update.cl_update_binhost_timestamp")
            if new_ts:
                new_ts = new_ts[0]
                if new_ts.isdigit():
                    ini = SystemIni(self.clVars)
                    ini.setVar('system', {'last_update': new_ts})
        if self.is_update_action(self.clVars.Get("cl_action")):
            value = self.clVars.GetBool('update.cl_update_binhost_stable_set')
            new_value = self.clVars.GetBool('update.cl_update_binhost_stable_opt_set')
            if value != new_value:
                self.clVars.Write(
                    'cl_update_binhost_stable_set',
                    self.clVars.Get('update.cl_update_binhost_stable_opt_set'),
                    location="system")
        return True

    def is_update_action(self, action):
        return action == 'sync'

    def save_with_bdeps(self):
        oldval = self.clVars.Get('cl_update_with_bdeps_set')
        newval = self.clVars.Get('cl_update_with_bdeps_opt_set')
        if oldval != newval:
            self.clVars.Write('cl_update_with_bdeps_set', newval,
                              location="system")
            self.clVars.Set('cl_update_force_depclean_set', 'on')
        return True

    def message_binhost_changed(self):
        if self.refresh_binhost:
            self.printWARNING(_("Update server was changed to %s") %
                              self.clVars.Get('update.cl_update_binhost'))
            self.clVars.Set("update.cl_update_package_cache_set",
                            Variable.On, force=True)
        else:
            self.printSUCCESS(_("Update server %s") %
                              self.clVars.Get('update.cl_update_binhost'))
        return True

    def delete_binhost(self):
        self.clVars.Delete('cl_update_binhost', location="system")
        try:
            bin_cache_fn = self.get_bin_cache_filename()
            if path.exists(bin_cache_fn):
                os.unlink(bin_cache_fn)
        except OSError:
            raise UpdateError(
                _("Failed to remove cached ini.env of binary repository"))
        try:
            for varname in ('update.cl_update_package_cache',
                            'update.cl_update_package_cache_sign'):
                fn = self.clVars.Get(varname)
                if path.exists(fn):
                    os.unlink(fn)
        except OSError:
            raise UpdateError(
                _("Failed to remove cached Package index"))
        # удалить binhost
        binhost_fn = self.inchroot(
            self.clVars.Get("update.cl_update_portage_binhost_path"))
        if path.exists(binhost_fn):
            os.unlink(binhost_fn)
        return False

    def update_binhost_list(self, dv=None):
        """
        Обновить список binhost'ов после обновления до master веток
        :return:
        """
        changes = False
        try:
            if dv is None:
                dv = DataVarsUpdate()
                dv.importUpdate()
                dv.flIniFile()
            for varname in ('update.cl_update_binhost_list',
                            'update.cl_update_binhost_unstable_list',
                            'update.cl_update_binhost_timestamp_path',
                            'update.cl_update_binhost_revision_path'):
                new_value = dv.Get(varname)
                old_value = self.clVars.Get(varname)
                if new_value != old_value:
                    changes = True
                    self.clVars.Set(varname, new_value, force=True)
        except DataVarsError as e:
            raise UpdateError(_("Failed to get values for binhost search"))

        if not changes:
            return False
        self.create_binhost_data()
        return True

    def drop_binhosts(self, dv):
        """
        Обновление до master веток
        """
        branch = dv.Get('update.cl_update_branch')
        revs = [
            branch for x in dv.Get('update.cl_update_rep_name')
            ]
        dv.Set('update.cl_update_branch_name', revs)
        dv.Invalidate('update.cl_update_rep_rev')
        return True

    def inchroot(self, fn):
        return pathJoin(self.clVars.Get("cl_chroot_path"), fn)

    def prepare_gpg(self):
        """
        Получить объект для проверки подписи, либо получить заглушку
        """
        gpg_force = self.clVars.Get('cl_update_gpg_force')
        gpg_keys = [self.inchroot(x)
                    for x in self.clVars.Get('cl_update_gpg_keys')]
        if gpg_force == "skip":
            return True
        gpgtmpdir = "/var/calculate/tmp/update"
        if not path.exists(gpgtmpdir):
            makeDirectory(gpgtmpdir)
        gpg = GPG(tempfile.mkdtemp(dir=gpgtmpdir,
                                   prefix="gpg-"))
        for keyfn in gpg_keys:
            if path.exists(keyfn):
                try:
                    key = readFile(keyfn)
                    gpg.import_key(key)
                except GPGError as e:
                    self.printWARNING(_("Failed to load public keys from '%s' "
                        "for signature checking") % keyfn)
        if not gpg.count_public():
            if gpg_force == "force":
                raise UpdateError(_("Public keys for Packages signature checking not found"))
            else:
                return True
        self.clVars.Set('update.cl_update_gpg', gpg, force=True)
        return True

    def download_packages(self, url_binhost, packages_fn, packages_sign_fn, gpg):
        quite_unlink(packages_fn)
        orig_packages = Binhosts.fetch_packages(url_binhost)
        try:
            with writeFile(packages_fn) as f:
                pi = PackagesIndex(orig_packages)
                pi["TTL"] = str(30 * DAYS)
                pi["DOWNLOAD_TIMESTAMP"] = str(int(time.time()))
                pi.write(f)
        except (OSError, IOError):
            raise UpdateError(_("Failed to save Packages"))
        self.endTask(True)
        self.startTask(_("Check packages index signature"))
        if not gpg:
            self.endTask("skip")
            self.clVars.Set('cl_update_package_cache_set', Variable.Off, force=True)
            return True
        try:
            Binhosts.check_packages_signature(
                url_binhost, orig_packages, gpg)
            with writeFile(packages_sign_fn) as f:
                f.write(Binhosts.fetch_packages_sign(url_binhost))
        except BinhostSignError:
            for fn in (packages_fn, packages_sign_fn):
                if path.exists(fn):
                    try:
                        os.unlink(fn)
                    except OSError:
                        pass
            self.clVars.Set("update.cl_update_bad_sign_set", Variable.On)
            self.clVars.Set('update.cl_update_binhost_recheck_set', Variable.On)
            self.clVars.Set('cl_update_package_cache_set', Variable.Off, force=True)
            raise
        return True

    class Reason(object):
        Success = 0
        BadSign = 1
        Outdated = 2
        Skip = 3
        Updating = 4
        WrongBinhost = 5
        BadEnv = 6
        EnvNotFound = 7
        SkipSlower = 8
        UnknownError = 9


        @staticmethod
        def humanReadable(reason):
            return {
                Update.Reason.WrongBinhost: "FAILED (Wrong binhost)",
                Update.Reason.Outdated: "OUTDATED",
                Update.Reason.Updating: "UPDATING",
                Update.Reason.BadEnv: "FAILED (Bad env)",
                Update.Reason.EnvNotFound: "FAILED (Env not found)",
                Update.Reason.UnknownError: "FAILED (Unknown error)",
                Update.Reason.BadSign: "FAILED (Bad sign)",
                Update.Reason.Skip: "SKIP",
                Update.Reason.SkipSlower: "",
                Update.Reason.Success: ""
            }.get(reason,reason)

    def _get_binhost_logger(self):
        return log("binhost-scan.log",
                   filename=pathJoin(
                       self.clVars.Get('cl_chroot_path'),
                       "/var/log/calculate/binhost-scan.log"),
                   formatter="%(message)s")

    def get_arch_machine(self):
        return self.clVars.Get('os_arch_machine')

    @variable_module("update")
    def create_binhost_data(self):
        dv = self.clVars
        last_ts = dv.Get('cl_update_last_timestamp')
        if dv.GetBool('cl_update_binhost_stable_opt_set'):
            binhost_list = dv.Get('cl_update_binhost_list')
        else:
            binhost_list = dv.Get('cl_update_binhost_unstable_list')
        self.binhosts_data = Binhosts(
            # значение малозначимо, поэтому берётся из собирающей системы
            dv.GetInteger('cl_update_binhost_timeout'),
            dv.Get('cl_update_binhost_revision_path'),
            dv.Get('cl_update_binhost_timestamp_path'),
            last_ts, binhost_list,
            self.get_arch_machine(),
            gpg=dv.Get('update.cl_update_gpg'))
        return True

    @variable_module("update")
    def _search_best_binhost(self, binhosts_data, stabilization):
        if not self.clVars.Get('cl_ebuild_phase'):
            logger = self._get_binhost_logger()
        if logger:
            logger.info(
                "Started scan on: {date}, current timestamp: {ts}".format(
                date=time.ctime(), ts=binhosts_data.last_ts))
        retval = []
        skip_check_status = False
        actual_reason = self.Reason.UnknownError
        for binhost in sorted(binhosts_data.get_binhosts(), reverse=True):
            host = binhost.host
            if not binhost.valid:
                reason = self.Reason.WrongBinhost 
            elif binhost.outdated:
                reason = self.Reason.Outdated 
            elif not skip_check_status:
                status = binhost.status
                if status is not binhosts_data.BinhostStatus.Success:
                    errors = {
                        binhosts_data.BinhostStatus.Updating: self.Reason.Updating,
                        binhosts_data.BinhostStatus.BadEnv: self.Reason.BadEnv,
                        binhosts_data.BinhostStatus.EnvNotFound: self.Reason.EnvNotFound 
                    }
                    reason = errors.get(status, self.Reason.UnknownError)
                elif binhost.bad_sign:
                    reason = self.Reason.BadSign
                else:
                    # SUCCESS
                    if not binhost.downgraded or stabilization:
                        host = "-> %s" % host
                        reason = self.Reason.Success
                    else:
                        reason = self.Reason.Skip
            elif binhost.downgraded:
                reason = self.Reason.Skip
            else:
                reason = self.Reason.SkipSlower

            if reason == self.Reason.Success:
                retval.append([binhost.host, binhost.data,
                            str(binhost.timestamp),
                            str(binhost.duration)])
                skip_check_status = True
            if reason < actual_reason:
                actual_reason = reason
            logger.info("{host:<60} {speed:<7} {timestamp:<10} {reason}".format(
                host=host, speed=float(binhost.duration) / 1000.0,
                timestamp=binhost.timestamp,
                reason=Update.Reason.humanReadable(reason)))
        if not retval:
            if actual_reason is self.Reason.BadSign:
                raise UpdateError(_("Failed to find the reliable server with appropriate updates"))
            elif actual_reason in (self.Reason.Outdated,
                                   self.Reason.Skip,
                                   self.Reason.Updating):
                raise UpdateError(_("Failed to find the server with appropriate updates"))
            else:
                raise UpdateError(_("Failed to find the working server with updates"))
        return retval
        
    def check_current_binhost(self, binhost_url):
        """
        Проверка текущего сервера обновлений на валидность
        """
        if not binhost_url in self.binhosts_data.binhost_list:
            raise UpdateError(_("Current binhost is absent in list of update servers"))
        binhost = self.binhosts_data.get_binhost(binhost_url)

        if binhost.valid and not binhost.outdated and not binhost.downgraded:
            if binhost.status == self.binhosts_data.BinhostStatus.Success:
                self.clVars.Set('update.cl_update_binhost_data',
                        [[binhost.host, binhost.data,
                         str(binhost.timestamp),
                         str(binhost.duration)]],
                         force=True)
                self.endTask()
        else:
            if not binhost.valid:
                raise UpdateError(
                    _("Current binhost {} is not valid").format(binhost_url))
            elif binhost.outdated:
                raise UpdateError(
                    _("Current binhost {} is outdated").format(binhost_url))
            elif binhost.downgraded:
                raise UpdateError(
                    _("Binary packages on the current binhost {} "
                      "are older than local").format(binhost_url))
        if self.binhosts_data.gpg:
            packages_fn = self.clVars.Get('update.cl_update_package_cache')
            packages_sign_fn = self.clVars.Get('update.cl_update_package_cache_sign')
            if path.exists(packages_fn) and path.exists(packages_sign_fn):
                packages_sign = readFile(packages_sign_fn)
                pi = PackagesIndex(readFile(packages_fn))
                pi.clean()
                try:
                    Binhosts.check_packages_signature(
                        None, pi.get_value(), self.binhosts_data.gpg,
                        sign=packages_sign)
                    return True
                except BinhostSignError:
                    for fn in (packages_fn, packages_sign_fn):
                        if path.exists(fn):
                            try:
                                os.unlink(fn)
                            except OSError:
                                pass
            if binhost.bad_sign:
                raise UpdateError(
                    _("Current binhost {} has wrong signature").format(
                        binhost_url))
        return True

    @variable_module("update")
    def detect_best_binhost(self):
        # выполняется переход с серверов unstable обновлней на stable
        # в этом случае не важно, что бинари могут старее текущих
        if (self.clVars.GetBool('cl_update_binhost_stable_opt_set') and
                not self.clVars.GetBool('cl_update_binhost_stable_set')):
            stabilization = True
        else:
            stabilization = False

        self.startTask(_("Searching new binhost"))
        retval = self._search_best_binhost(self.binhosts_data, stabilization)

        self.clVars.Set('update.cl_update_binhost_data',
            retval or Variable.EmptyTable, force=True)

        self.endTask()
        return True

    def update_layman(self):
        """
        Обновить базу layman
        :param builder_path:
        :return:
        """
        cmd = "/usr/bin/layman"
        cmd_path = self.get_prog_path(cmd)
        if not cmd_path:
            raise UpdateError(_("Failed to find the %s command") % cmd)
        layman = emerge_parser.CommandExecutor(cmd_path, ["-f"])
        layman.execute()
        return layman.success()

    def rename_custom_files(self):
        """
        Переименовать все custom файлы: keywords, use, sets и т.д. в связи
        с изменением профиля
        """
        newdv = self.clVars.Get("cl_update_profile_datavars")
        cur_short = self.clVars.Get("os_linux_shortname").lower()
        new_short = newdv["os_linux_shortname"].lower()
        if cur_short != new_short:
            for fn in ("/etc/portage/package.keywords/custom.{}",
                       "/etc/portage/package.use/custom.{}",
                       "/etc/portage/package.mask/custom.{}",
                       "/etc/portage/package.unmask/custom.{}",
                       "/etc/portage/sets/custom.{}",
                       "/etc/portage/make.conf/custom.{}"):
                fn_source = fn.format(cur_short)
                fn_target = fn.format(new_short)
                try:
                    if path.exists(fn_source) and not path.exists(fn_target):
                        os.rename(fn_source, fn_target)
                except (OSError, IOError) as e:
                    self.printWARNING(str(e))
            world_sets_fn = "/var/lib/portage/world_sets"
            if path.exists(world_sets_fn):
                worlds_sets = readFile(world_sets_fn)
                new_worlds_sets = re.sub("^@custom.{}$".format(cur_short),
                                         "@custom.{}".format(new_short),
                                         worlds_sets, flags=re.M)
                try:
                    with open(world_sets_fn, 'w') as fd:
                        fd.write(new_worlds_sets)
                except IOError as e:
                    self.printWARNING(str(e))
        return True
