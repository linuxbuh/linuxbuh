# -*- coding: utf-8 -*-

# Copyright 2012-2016 Mir Calculate. http://www.calculate-linux.org
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

import pickle
import random
import threading
import sys
reload(sys);
sys.setdefaultencoding('utf8')
import os
import re
from os import path
import glob
import traceback
from traceback import print_exc
from calculate.core.server.core_interfaces import (CoreServiceInterface,
                                                   MethodsInterface)
from calculate.install.distr import Distributive
from calculate.lib.cl_log import log
from calculate.lib.utils.colortext import convert_console_to_xml
from api_types import ReturnProgress
from calculate.lib.cl_lang import setLocalTranslate, getLazyLocalTranslate

_ = lambda x: x
setLocalTranslate('cl_core3', sys.modules[__name__])
__ = getLazyLocalTranslate(_)

from calculate.lib.utils.files import (process, readFile, processProgress,
                                       readLinesFile,
                                       makeDirectory, getProgPath)
from calculate.lib.datavars import DataVarsError, CriticalError, Variable
from calculate.lib.utils.content import getCfgFiles
from itertools import *

from soaplib.serializers.primitive import String, Integer, Boolean
from soaplib.serializers.clazz import Array
from soaplib.service import rpc
from calculate.core.server.api_types import ReturnedMessage, CommonInfo
from calculate.core.server.api_types import (Field,
                                             GroupField, ViewInfo, ViewParams)
from calculate.lib.cl_template import Template
from calculate.lib.datavars import DataVars
from loaded_methods import LoadedMethods


class CommonMethods(MethodsInterface):
    def dispatchConf(self, filesApply=None, prefix="/"):
        """
        Common dispatch conf. Using if ._cfg files created.
        """

        def normalize_config(text):
            """
            Нормализовать конфигурационный файл для сравнения:
            * удалить calculate заголовок
            * добавить перевод строки в конец если файл без перевода строки
            """
            if text.endswith('\n'):
                return Template.removeComment(text)
            else:
                return "%s\n" % Template.removeComment(text)

        i_orig, i_data = 0, 1
        i_mime, i_cfgname = 0, 1
        cfg_files = getCfgFiles(prefix=prefix).items()
        info = filter(lambda x: (filesApply is None or
                                 x[i_data][0][i_cfgname] in filesApply),
                      cfg_files)
        max_info = len(info)
        for ind, data in enumerate(info):
            out = []
            orig, data = data
            data = data[0]

            origdata = readFile(orig)
            newdata = readFile(data[i_cfgname])
            pattern = "%s/._cfg????_%s" % (os.path.dirname(orig),
                                           os.path.basename(orig))
            answ_map = {'usenew': 'use new', 'skip': 'next'}
            dispatch_var = self.clVars.Get('cl_dispatch_conf')
            for fn in glob.glob(pattern):
                try:
                    if fn == data[i_cfgname]:
                        continue
                    os.unlink(fn)
                except (OSError, IndexError):
                    pass
            if (self.clVars.Get('cl_autoupdate_set') == 'on' or
                        origdata == newdata):
                answ = "use new"
            elif dispatch_var in answ_map:
                answ = answ_map.get(dispatch_var)
            else:
                orig_content = normalize_config(readFile(orig))
                new_content = normalize_config(readFile(data[i_cfgname]))
                if orig_content == new_content:
                    answ = "use new"
                else:
                    for i, s in enumerate(list(process("diff", "-Nu",
                                                       orig, data[i_cfgname]))):
                        s = convert_console_to_xml(s)
                        if s.startswith('+') and i > 1:
                            out.append('<font color="green">%s</font>' % s)
                        elif s.startswith('-') and i > 1:
                            out.append('<font color="red">%s</font>' % s)
                        else:
                            out.append(s)
                    self.printPre("<br/>".join(out))
                    self.printSUCCESS(_("({one} of {_all}) -- {fname}").format(
                        one=ind + 1, _all=max_info, fname=orig))
                    answ = self.askChoice(_("Choose a configuration action:"),
                                          answers=(("zap new", _("Zap new")),
                                                   ("use new", _("Use new")),
                                                   ("next", _("Next"))))
            if answ == "next":
                continue
            elif answ == "use new":
                try:
                    with open(orig, 'w') as fd:
                        fd.write(readFile(data[i_cfgname]))
                    os.unlink(data[i_cfgname])
                    if filesApply:
                        try:
                            i = filesApply.index(data[i_cfgname])
                            filesApply[i] = orig
                        except Exception as e:
                            print str(e)
                except Exception as e:
                    print str(e)
                    self.printERROR(
                        _("Failed to copy {ffrom} to {fto}").format(
                            ffrom=data[i_cfgname], fto=orig))
                    continue
            elif answ == "zap new":
                try:
                    os.unlink(data[i_cfgname])
                    if filesApply:
                        try:
                            filesApply.remove(data[i_cfgname])
                        except Exception as e:
                            print str(e)
                except OSError:
                    self.printERROR(
                        _("Failed to remove %s") % data[i_cfgname])
        return True

    def setVariable(self, varname, varvalue, force=False):
        """
        Установить значение переменной
        """
        self.clVars.Set(varname, varvalue, force=force)
        return True

    def invalidateVariables(self, *variables):
        for varname in (x.rpartition('.')[2] for x in variables):
            self.clVars.Invalidate(varname, force=True)
        return True

    def applyTemplates(self, target=None, useClt=None, cltFilter=False,
                       root=None, useDispatch=True, critical=False):
        """
        Применить шаблоны.
        
        Args:
        target: дистрибутив, куда необходимо выполнить шаблоны (/ по умолчанию)
        useClt: использовать clt шаблоны
        cltFilter: применять фильтр на clt шаблоны
        root: каталог, куда будут наложны шаблоны (cl_root_path)
        """
        from calculate.lib.cl_template import (TemplatesError, ProgressTemplate)

        if target is None:
            chroot = '/'
        elif isinstance(target, Distributive):
            chroot = target.getDirectory()
        else:
            chroot = target
        if root is None:
            root = '/'
        elif isinstance(root, Distributive):
            root = root.getDirectory()
        clt_filter = True if cltFilter in (True, "on") else False
        self.clVars.Set("cl_chroot_path", chroot, True)
        self.clVars.Set("cl_root_path", root, True)
        # определение каталогов содержащих шаблоны
        use_clt = useClt in ("on", True)
        self.addProgress()
        null_progress = lambda *args, **kw: None
        dispatch = self.dispatchConf if useDispatch else None
        cl_templ = ProgressTemplate(null_progress, self.clVars,
                                    cltObj=use_clt,
                                    cltFilter=clt_filter,
                                    printSUCCESS=self.printSUCCESS,
                                    printWARNING=self.printWARNING,
                                    askConfirm=self.askConfirm,
                                    dispatchConf=dispatch,
                                    printERROR=self.printERROR,
                                    critical=critical)
        try:
            cl_templ.applyTemplates()
            if cl_templ.hasError():
                if cl_templ.getError():
                    raise TemplatesError(cl_templ.getError())
        finally:
            if cl_templ:
                if cl_templ.cltObj:
                    cl_templ.cltObj.closeFiles()
                cl_templ.closeFiles()
        return True


class CommonLink(object):
    """
    Объект-связка объектов тип Install,Client,Action с Common объектом
    """
    com = None

    @staticmethod
    def link_object(source, target):
        for fn in (x for x in dir(CoreWsdl.Common) if not x.startswith("_")):
            if hasattr(source, fn):
                setattr(target, fn, getattr(source, fn))

    def set_link(self, com):
        """
        Установить связь с Common объектом
        """
        self.com = com
        self.link_object(com, self)


class ActionError(Exception):
    pass


class Tasks(object):
    """
    Класс для создания проверок необходимости запуска задачи в зависимости
    от результатра работы предыдущих задач
    """

    def __init__(self, check):
        self.check = check

    def __call__(self, result, all_result):
        return self.check(result, all_result)

    def __or__(self, y):
        return Tasks(lambda result, all_result: self(result, all_result) or y(result, all_result))

    def __ror__(self, y):
        return Tasks(lambda result, all_result: y(result, all_result) or self(result, all_result))

    def __and__(self, y):
        return Tasks(lambda result, all_result: self(result, all_result) and y(result, all_result))

    def __rand__(self, y):
        return Tasks(lambda result, all_result: y(result, all_result) and self(result, all_result))

    def __invert__(self):
        return Tasks(lambda result, all_result: not self(result, all_result))

    @classmethod
    def _result(self, result, all_result):
        return result

    @classmethod
    def success_all(cls, *tasks):
        """
        Все указанные задачи выполнены и выполнены без ошибок
        """
        return cls(
            lambda *args: all(x in cls._result(*args) and cls._result(*args)[x] for x in tasks))

    @classmethod
    def success_one_of(cls, *tasks):
        """
        Хотя бы одна из задач выполнена и хотя бы одна из выполненных без ошибок
        """
        return cls(
            lambda *args: any(cls._result(*args)[x] for x in tasks if x in cls._result(*args)))

    @classmethod
    def success(cls, inessential=()):
        """
        Все ранее запущенные задачи успешно завершены, результат задач
        inessential не важен
        """
        return cls(lambda *args: all(cls._result(*args)[x] for x in cls._result(*args)
                                     if x not in inessential))

    @classmethod
    def failed(cls, inessential=()):
        """
        Хотя бы одна из задач завершилась неудачно, результат задач
        inessential не важен
        """
        return cls(lambda *args: any(not cls._result(*args)[x] for x in cls._result(*args)
                                        if x not in inessential))

    @classmethod
    def failed_all(cls, *tasks):
        """
        Выполнена хотя бы одна задача и все те, которые выполнены с ошибкой
        """
        return cls(
            lambda *args: any(not cls._result(*args)[x] for x in tasks if x in cls._result(*args)))

    @classmethod
    def failed_one_of(cls, *tasks):
        """
        Хотя бы одна из указанных задач выполнена и выполнена с ошибкой
        """
        return cls(
            lambda *args: any(x in cls._result(*args) and not cls._result(*args)[x] for x in tasks))

    @classmethod
    def has(cls, *tasks):
        """
        Был запуск всех перечисленных задач
        """
        return cls(lambda *args: all(x in cls._result(*args) for x in tasks))

    @classmethod
    def hasnot(cls, *tasks):
        """
        Не было запуска ни одной из перечисленных задач
        """
        return cls(lambda *args: all(x not in cls._result(*args) for x in tasks))

    @classmethod
    def result(cls, task, eq=None, ne=None):
        if eq:
            wrapper = lambda *args: task in cls._result(*args) and cls._result(*args)[task] == eq
        elif ne:
            wrapper = lambda *args: task not in cls._result(*args) or cls._result(*args)[task] != ne
        else:
            wrapper = lambda *args: task in cls._result(*args) and cls._result(*args)[task]
        return cls(wrapper)

    @classmethod
    def has_any(cls, *tasks):
        """
        Был запуск любой из задач
        """
        return cls(lambda *args: any(x in cls._result(*args) for x in tasks))


class AllTasks(Tasks):
    @classmethod
    def _result(cls, result, all_result):
        return all_result

class Action(MethodsInterface):
    """
    Класс для реализации выполнения действия
    # default = {'depend':Tasks.success(),
    #           # прятать вывод
    #           'hideout':False,
    #           # задача важна, в случае False результат
    #           # не сохраняется в self.result
    #           'essential':True}
    """
    eachvar = None

    # список выполняемых задач
    tasks = []
    # список исключений, которые выводятся в сокращенном формате
    # (ожидаемые ошибки)
    # остальные выводятся с именем модуля и номером строки
    native_error = ()

    # сообщение об удачном завершении действия
    successMessage = None
    # сообщение при ошибке
    failedMessage = None
    # сообщение о прерывании
    interruptMessage = None

    # добавить стандартные сообщения в конце
    finishMessage = True

    def __init__(self):
        if self.finishMessage:
            tasks = []
            if self.failedMessage:
                tasks.append(
                    # вывести сообщение в случае ошибки
                    {'name': 'failed',
                     'error': self.failedMessage,
                     'depend': (Tasks.failed() & Tasks.hasnot("interrupt"))})
            if self.successMessage:
                tasks.append(
                    # вывести сообщение в случае успеха
                    {'name': 'success',
                     'message': self.successMessage,
                     'depend': (Tasks.success() & Tasks.hasnot("failed"))})
            if self.interruptMessage:
                tasks.append(
                    # вывести сообщение о том, что действие прервано
                    {'name': 'intmessage',
                     'error': self.interruptMessage,
                     'depend': (Tasks.has("interrupt"))})
            self.tasks = self.tasks + tasks
        self.group_name = ""
        self.clVars = None

    @classmethod
    def program(cls, progName):
        """
        Проверить наличие программы
        """
        return lambda dv: bool(getProgPath(progName))

    @classmethod
    def packageInstalled(cls, pkg):
        """
        Проверить было ли обновление пакета
        """
        return lambda dv: False

    @classmethod
    def variables(cls, *varnames):
        """
        Передать переменные как аргументы, поддерживается True,False
        """
        return lambda dv: [dv.Get(x) if x not in (True, False) else x
                           for x in varnames]

    reMethod = re.compile("^([A-Za-z]+)\.([A-Za-z0-9_]+)\(([^)]*)\)$")
    reMessageVars = re.compile("\{([^}]+)\}")

    def parseMethod(self, objs, dv, s, task):
        """
        Разобрать строку метода, на объект, метод, аргументы
        """
        result = self.reMethod.search(s)
        if not result:
            raise ActionError(_("Wrong method for task %s") % task)
        objname, methodname, args = result.groups()
        if objname not in objs:
            raise ActionError(_("Object %s not found") % objname)
        obj = objs[objname]
        if not hasattr(obj, methodname):
            raise ActionError(_("Method {method} for {obj} not found").
                              format(method=methodname, obj=objname))

        def _convertMethodArg(param):
            """
            Конвертировать аргумент для метода, взять по словарю,
            либо строка - имя переменной
            """
            param = param.strip()
            mapstd = {'True': True,
                      'False': False,
                      'None': None,
                      '""': "",
                      "''": ""}
            if param in mapstd:
                return mapstd[param]
            if param.isdigit():
                return int(param)
            if param.startswith('"') and param.endswith('"'):
                return param.strip('"')
            if param == 'eachvar':
                return self.eachvar
            _type = dv.getInfo(param).type
            if _type == "int":
                return dv.GetInteger(param)
            if _type in ("bool", "boolauto"):
                return dv.GetBool(param)
            return dv.Get(param)

        if args:
            args = map(_convertMethodArg, args.split(','))
        else:
            args = ()
        return getattr(obj, methodname), args

    def formatMessage(self, dv, message):
        """
        Вставить значения переменных в текст сообщения
        """

        class TextTrasformer(object):

            @staticmethod
            def first_letter_upper(s):
                return "%s%s" % (s[0].upper(), s[1:])

        tt = TextTrasformer()

        def replace_value(match):
            var = match.group(1)
            if ":" in var:
                var, func = var.split(':')
            else:
                func = None
            if var == "eachvar":
                val = self.eachvar
            else:
                val = dv.Get(var)
            if type(val) in (list, tuple):
                val = ", ".join(val)
            if func:
                if hasattr(tt, func):
                    val = getattr(tt, func)(val)
                else:
                    val = getattr(val, func)()
            return "{0}".format(val)

        return self.reMessageVars.sub(replace_value, str(message))

    def runCondition(self, func_condition):
        """
        Запустить метод проверки условия (если аргумент называется Get,
        то передавать в него не объект DataVars а метод Get,
        если у нет аргументов, то не передавать туда аргументы
        """
        args = []
        arg_count = func_condition.func_code.co_argcount
        for param_name in func_condition.func_code.co_varnames[:arg_count]:
            if param_name in ('Get', 'GetBool', 'Select', 'ZipVars'):
                args.append(getattr(self.clVars, param_name))
            elif param_name == 'eachvar':
                args.append(self.eachvar)
            else:
                args.append(self.clVars)
        return func_condition(*args)

    def getFormatMessage(self, action, *fields):
        """
        Получить сообщение для вывода среди нескольких с приоритетом и
        метод вывода
        """
        for field in (x for x in fields if x in action):
            if "error" in field:
                print_func = self.printERROR
            elif "warning" in field:
                print_func = self.printWARNING
            else:
                print_func = self.printSUCCESS
            return print_func, self.formatMessage(self.clVars, action[field])
        return None, None

    def get_tasks(self, tasks, result, all_result):
        """
        Герератор задач (поддержка линейной обработки задач в группах)
        """
        for task in tasks:
            if "group" in task or "tasks" in task:
                if all(self.get_condition_context(task, result,
                                                  all_result).values()):
                    self.group_name = task.get("group", "")
                    if "while" in task:
                        depend = task.get("while", [])
                        depend = (depend
                                  if type(depend) in (list, tuple) else [depend])
                        depend.append(~Tasks.has_any("interrupt"))
                        while all([x(result, all_result) for x in depend]):
                            for action in self.get_tasks(task["tasks"],
                                                         result, all_result):
                                yield action
                    else:
                        for action in self.get_tasks(task["tasks"], result,
                                                     all_result):
                            yield action
                    if not self.group_name:
                        self.endGroup()
                    else:
                        self.group_name = ""
            else:
                yield task

    def get_condition_context(self, action, result, all_result):
        """
        Получить результаты проверки по зависимосятм и условиям
        """
        group, op, name = action.get("name",
                                     "<unknown>").rpartition(':')
        # проверить по результатам
        # если указанно группа к имени с '!', то проверяется
        # только условие принадлежности задачи к группе
        if group and group.endswith('!'):
            group = group.strip('!')
            depend = [Tasks.success_all(group)]
        else:
            depend = action.get("depend", Tasks.success())
            depend = (depend
                      if type(depend) in (list, tuple) else [depend])
            if group:
                depend.append(Tasks.success_all(group))
        depend_result = all([x(result, all_result) for x in depend])
        # проверить по условиям
        if depend_result:
            condition_funcs = action.get("condition", lambda dv: True)
            condition_funcs = (condition_funcs
                               if type(condition_funcs) in (list, tuple)
                               else [condition_funcs])
            condition_result = all(
                [self.runCondition(x) for x in condition_funcs])
        else:
            condition_result = True
        return {'condition': condition_result, 'depend': depend_result}

    def run(self, objs, dv):
        """Запустить список действий"""

        class StubLogger(object):
            def info(self, s):
                pass

        result = {}
        all_result = {}

        self.group_name = ""
        self.clVars = dv
        if dv.Get('cl_env_debug_set') == 'off' or \
                dv.Get('cl_root_readonly') == 'on' or \
                dv.Get('cl_ebuild_phase') or os.getuid():
            logger = StubLogger()
        else:
            logger = log("core-action.log",
                         filename="/var/log/calculate/core-action.log",
                         formatter="%(asctime)s - %(levelname)s - %(message)s")
        for obj in objs.values():
            obj.set_link(self)
            obj.clVars = dv
            if hasattr(obj, "init"):
                obj.init()
        try:
            self.beginFrame()
            logger.info("Start {methodname}".format(
                methodname=self.method_name))
            for action in self.get_tasks(self.tasks, result, all_result):
                foreach = action.get("foreach", "")
                if foreach:
                    foreach = self.clVars.Get(foreach)
                else:
                    foreach = [""]
                self.eachvar = ""
                for eachvar in foreach:
                    self.eachvar = eachvar
                    group, op, name = action.get("name",
                                                 "<unknown>").rpartition(':')
                    res = True
                    task = False
                    self.clVars.Set('cl_task_name', name, force=True)
                    try:
                        run_context = self.get_condition_context(action, result,
                                                                 all_result)
                        actinfo = "Run" if all(run_context.values()) else "Skip"
                        logger.info(
                            "{action} {name}: condition: {condition}, "
                            "depend: {depend}".format(
                                action=actinfo,
                                name=name,
                                condition=run_context['condition'],
                                depend=run_context['depend']))

                        elsePrint, elseMessage = (
                            self.getFormatMessage(action, "else_error",
                                                  "else_warning",
                                                  "else_message"))
                        if (run_context['depend'] and
                                not run_context['condition'] and elseMessage):
                            if "else_error" in action:
                                all_result[name] = False
                                if action.get("essential", True):
                                    result[name] = False
                            elsePrint(elseMessage)
                        if all(run_context.values()):
                            self.writeFile()
                            if self.group_name:
                                self.startGroup(str(self.group_name))
                                self.group_name = None
                            printFunc, message = self.getFormatMessage(
                                action, "error", "warning", "message")
                            if "confirm" in action and message:
                                all_result[name] = \
                                    self.askConfirm(str(message),
                                                    action["confirm"])
                                result[name] = all_result[name]
                                continue
                            elif message:
                                # если действие с командой
                                if ("error" not in action and
                                            "method" in action or
                                            "command" in action):
                                    self.startTask(str(message))
                                    task = True
                                # действие содержит только сообщение
                                else:
                                    if "error" in action:
                                        res = False
                                    printFunc(message)
                            # запустить метод объекта
                            if "method" in action:
                                try:
                                    method, args = self.parseMethod(
                                        objs, dv, action["method"], name)
                                    if "decoration" in action:
                                        decfunc, decargs = self.parseMethod(
                                            objs, dv, action["decoration"],
                                            name)
                                        method = decfunc(*decargs)(method)
                                    res = method(*args)
                                    if res is None:
                                        res = False
                                except CriticalError as e:
                                    self.printERROR(str(e))
                                    self.endFrame()
                                    return False
                                except self.native_error as e:
                                    if action.get('essential', True):
                                        printerror = self.printERROR
                                    else:
                                        printerror = self.printWARNING
                                    if hasattr(e, "addon") and e.addon:
                                        printerror(str(e.addon))
                                    printerror(str(e))
                                    res = False
                                except Exception:
                                    error = shortTraceback(*sys.exc_info())
                                    self.printERROR(error)
                                    res = False
                            # запустить системную команду
                            if "command" in action:
                                hideout = action.get("hideout", False)
                                cmdParam = map(lambda x: x.strip('"\''),
                                               re.findall(
                                                   '["\'][^"\']+["\']|\S+',
                                                   action["command"]))
                                cmd = processProgress(*cmdParam)
                                for line in cmd.progress():
                                    if not hideout:
                                        self.printSUCCESS(line)
                                if cmd.failed():
                                    lineCmd = cmd.pipe.stderr.read().split('\n')
                                    for line in filter(None, lineCmd):
                                        self.printERROR(line)
                                res = cmd.success()
                            all_result[name] = res
                            if action.get("essential", True):
                                result[name] = res
                            failedPrint, failedMessage = (
                                self.getFormatMessage(action, "failed_error",
                                                      "failed_warning",
                                                      "failed_message"))
                            if not res and failedPrint:
                                failedPrint(failedMessage)
                            if task and res in (True, False, "skip"):
                                self.endTask(res)
                            logger.info("{name}: Result is {result}".format(
                                name=name, result=res))
                            if res is True:
                                on_success = action.get('on_success', None)
                                if on_success:
                                    on_success()
                                    # else:
                                    #    print "[-] Skip ",name
                    except KeyboardInterrupt:
                        all_result[name] = False
                        if action.get("essential", True):
                            result[name] = False
                        self.endTask(False)
                        self.printWARNING(_("Task interrupted"))
                        all_result["interrupt"] = False
                        result["interrupt"] = False
                        logger.info("{name}: Interrupeted".format(name=name))
                    except self.native_error as e:
                        if action.get('essential', True):
                            printerror = self.printERROR
                        else:
                            printerror = self.printWARNING
                        if hasattr(e, "addon") and e.addon:
                            printerror(str(e.addon))
                        printerror(str(e))
                        result[name] = False
                        all_result[name] = False
                        logger.info("{name}: Native error".format(name=name))
                    except CriticalError as e:
                        self.printERROR(str(e))
                        self.endFrame()
                        return False
                    except BaseException as e:
                        result[name] = False
                        all_result[name] = False
                        error = shortTraceback(*sys.exc_info())
                        self.printERROR("%s:%s" % (name, error))
                        logger.info("{name}: Unknown exception {exp}".format(
                            name=name, exp=e.__class__.__name__))
        finally:
            dv.close()
        self.endFrame()
        if any(x in ("failed", "interrupt") for x in result):
            return False
        return True


def commonView(self, sid, params, arg):
    dv = self.get_cache(sid, arg, "vars")
    if not dv:
        dv = getattr(self, "%s_vars" % arg)()
    else:
        dv.processRefresh()
    view = ViewInfo(dv, viewparams=params)
    self.set_cache(sid, arg, "vars", dv, smart=False)
    return view


def catchExcept(*skipException):
    class wrapper:
        def __init__(self, f):
            self.f = f
            self.func_name = f.func_name
            self.func_code = f.func_code
            self.__doc__ = f.__doc__
            self.__name__ = f.__name__

        def __call__(self, *args, **kwargs):
            try:
                return self.f(*args, **kwargs)
            except BaseException as e:
                from calculate.core.server.api_types import ViewInfo, \
                    GroupField, Field

                if isinstance(e, KeyboardInterrupt):
                    error = _("Task interrupted")
                else:
                    error = str(e)
                view = ViewInfo(groups=[])
                group = GroupField(name=_("Error"), last=True)
                group.fields = []
                group.fields.append(Field(
                    name="error",
                    label=error,
                    default='color:red;',
                    element="error"))
                view.groups.append(group)

                if not any(isinstance(e, x)
                           for x in chain(skipException, (KeyboardInterrupt,))):
                    print shortTraceback(*sys.exc_info())

                return view

    return wrapper


def shortTraceback(e1, e2, e3):
    """
    Return short traceback
    """
    frame = e3
    for i in apply(traceback.format_exception, (e1, e2, e3)):
        print i,
    while frame.tb_next:
        frame = frame.tb_next
    module, part = os.path.split(frame.tb_frame.f_code.co_filename)
    if part.endswith('.py'):
        part = part[:-3]
    fallbackmod = part
    modname = [part]
    while module != '/' and not module.endswith('site-packages'):
        module, part = os.path.split(module)
        modname.insert(0, part)
    if module.endswith('site-packages'):
        modname = ".".join(modname)
    else:
        modname = fallbackmod
    return "%s:%s(%s:%s)" % (e1.__name__, str(e2), modname, frame.tb_lineno)


class ActiveClientStatus(object):
    Success = 0
    Failed = 1
    WrongSID = 2


class CoreWsdl(CoreServiceInterface):
    # client signals about presence
    def active_clients(self, sid):
        # curThread = threading.currentThread()
        #        REMOTE_ADDR = curThread.REMOTE_ADDR
        self.get_lang(sid, "from active clients")
        if 0 < sid < self.max_sid:
            try:
                # open file its session
                sid_file = self.sids + "/%d.sid" % sid
                if not os.path.isfile(sid_file):
                    return ActiveClientStatus.Failed
                # check sid in sid.db
                if not (os.path.isfile(self.sids_file) and
                            self.find_sid_in_file(sid)):
                    try:
                        os.unlink(sid_file)
                    except (OSError, IOError):
                        pass
                    return ActiveClientStatus.Failed
                with self.sid_locker:
                    with open(sid_file) as fd:
                        # read information about session
                        sid_inf = pickle.load(fd)
                        # reset counters
                        sid_inf[1] = 0
                        sid_inf[2] = 0
                    fd.close()
                    if not os.path.isfile(sid_file):
                        return ActiveClientStatus.Failed
                    fd = open(sid_file, "w")
                    pickle.dump(sid_inf, fd)
                    fd.close()
                return ActiveClientStatus.Success
            except Exception:
                return ActiveClientStatus.Failed
        else:
            return ActiveClientStatus.WrongSID

    def serv_get_methods(self, client_type):
        curThread = threading.currentThread()
        certificate = curThread.client_cert
        from cert_cmd import find_cert_id

        cert_id = find_cert_id(certificate, self.data_path, self.certbase)

        rights = self.serv_view_cert_right(cert_id, self.data_path, client_type)
        return_list = []
        if client_type == "console":
            for meth in self.return_conMethod():
                right_flag = True
                for right in LoadedMethods.rightsMethods[meth[1]]:
                    if right not in rights:
                        right_flag = False
                if right_flag:
                    return_list.append(meth)
            if not len(return_list):
                return [['0', '0']]
            return return_list
        else:
            for meth in self.return_guiMethod():
                right_flag = True
                for right in LoadedMethods.rightsMethods[meth[1]]:
                    if right not in rights:
                        right_flag = False
                if right_flag:
                    return_list.append(meth)
            if not len(return_list):
                return [['0', '0']]
            return return_list

    # return a list of methods for the console as list
    def return_conMethod(self):
        from loaded_methods import LoadedMethods

        results = []
        for item in LoadedMethods.conMethods:
            temp = [item]
            for i in LoadedMethods.conMethods[item]:
                temp.append(i)
            results.append(temp)
        return results

    # return a list of methods for the GUI as list
    def return_guiMethod(self):
        from loaded_methods import LoadedMethods

        results = []
        dv = DataVars()
        dv.importVariables()

        for item in LoadedMethods.guiMethods:
            for i in range(0, len(LoadedMethods.guiMethods[item]), 4):
                if LoadedMethods.guiMethods[item][i + 3]:
                    method_on = LoadedMethods.guiMethods[item][i + 3](dv.Get)
                else:
                    method_on = True
                if method_on:
                    temp = [item]
                    for j in range(3):
                        temp.append(LoadedMethods.guiMethods[item][i + j])
                    results.append(temp)
        dv.close()
        return results

    # get available sessions
    def serv_get_sessions(self):
        result = []
        fd = open(self.sids_file, 'r')
        while 1:
            try:
                # read all on one record
                list_sid = pickle.load(fd)
            except (KeyError, IOError, EOFError):
                break
            # if session id found
            result.append(str(list_sid[0]))
        fd.close()
        return result

    # check client alive
    def client_alive(self, sid, SIDS_DIR):
        sid_path = SIDS_DIR + "/%d.sid" % sid
        if not os.path.isfile(sid_path):
            return 1
        with self.sid_locker:
            with open(sid_path) as fd:
                # read information about session
                sid_inf = pickle.load(fd)
                # flag absence client
            fd.close()
            if sid_inf[2] == 1:
                return 0
            else:
                return 1

    class Common(CommonMethods, MethodsInterface):
        """ class to interact with the processes """

        def __init__(self, process_dict, progress_dict, table_dict,
                     frame_list, pid):
            self.process_dict = process_dict
            self.progress_dict = progress_dict
            self.progress_dict['id'] = 0
            self.table_dict = table_dict
            self.frame_list = frame_list
            self.pid = pid
            self.Num = 100000

        def pauseProcess(self):
            from calculate.core.server.gen_pid import ProcessStatus

            self.method_status = ProcessStatus.Paused
            self.writeFile()

        def resumeProcess(self):
            from calculate.core.server.gen_pid import ProcessStatus

            self.method_status = ProcessStatus.Worked
            self.writeFile()

        def writeFile(self):
            """ write data in file """
            from baseClass import Basic
            from calculate.core.server.gen_pid import ProcessMode

            if not os.path.exists(Basic.pids):
                makeDirectory(Basic.pids)
            build_id = ""
            try:
                from calculate.builder.variables.action import Actions

                if self.clVars.Get('cl_action') in Actions.All:
                    build_id = self.clVars.Get('builder.cl_builder_id')
            except Exception as e:
                if isinstance(e, KeyboardInterrupt):
                    raise

            pid_file = path.join(Basic.pids, '%d.pid' % self.pid)
            try:
                with open(pid_file, 'w') as f:
                    d = {'name': self.process_dict['method_name'],
                         'mode': ProcessMode.CoreDaemon,
                         'os_pid': os.getpid(),
                         'status': self.process_dict['status'],
                         'id': build_id
                         }
                    pickle.dump(d, f)
            except (IOError, OSError) as e:
                print str(e)
                print _("Failed to write the PID file %s!") % pid_file

        def setProgress(self, perc, short_message=None, long_message=None):
            try:
                id = self.progress_dict['id']
                self.progress_dict[id] = ReturnProgress(perc, short_message,
                                                        long_message)
            except IOError:
                pass

        def setStatus(self, stat):
            self.process_dict['status'] = stat

        def setData(self, dat):
            self.data_list = dat

        def getStatus(self):
            try:
                return self.process_dict['status']
            except IOError:
                return -1

        def getProgress(self):
            try:
                id = self.progress_dict['id']
                if id in self.progress_dict:
                    return self.progress_dict[id].percent
            except IOError:
                pass
            return 0

        def getAnswer(self):
            import time

            while self.process_dict['answer'] is None:
                time.sleep(0.5)
            res = self.process_dict['answer']
            self.process_dict['answer'] = None
            self.frame_list.pop(len(self.frame_list) - 1)
            self.process_dict['counter'] -= 1
            return res

        def addProgress(self, message=""):
            id = random.randint(1, self.Num)
            while id in self.progress_dict:
                id = random.randint(1, self.Num)
            self.progress_dict['id'] = id
            self.progress_dict[id] = ReturnProgress(0, '', '')
            self.addMessage(type='progress', id=id)

        def printTable(self, table_name, head, body, fields=None,
                       onClick=None, addAction=None, step=None,
                       records=None):
            id = random.randint(1, self.Num)
            while id in self.table_dict:
                id = random.randint(1, self.Num)

            from api_types import Table

            table = Table(head=head, body=map(lambda x: map(str, x), body),
                          fields=fields,
                          onClick=onClick, addAction=addAction, step=step,
                          values=None, records=records)
            self.table_dict[id] = table
            self.addMessage(type='table', message=table_name, id=id)

        def addMessage(self, type='normal', message=None, id=None,
                       onlyShow='', default=None):
            from api_types import Message

            re_clean = re.compile('\[(?:\d+;)?\d+m')
            messageObj = Message(
                type=type,
                message=(
                    None if message in (None, True, False)
                    else re_clean.sub('', filter(lambda x: x >= ' ', message))),
                result=message if message in (True, False) else None,
                id=id, onlyShow=onlyShow, default=default)
            try:
                self.frame_list.append(messageObj)
            except BaseException as e:
                if isinstance(e, KeyboardInterrupt):
                    raise
                print _(("%s:" % type) + str(message))

        def dropProgress(self):
            perc = self.getProgress()
            if perc == 0:
                self.setProgress(100)
            elif self.getProgress() > 0:
                self.setProgress(0 - self.getProgress())
            else:
                # self.setProgress(-100)
                self.setProgress(perc)

        def printSUCCESS(self, message='', onlyShow=None):
            self.dropProgress()
            self.addMessage(type='normal', message=message,
                            onlyShow=onlyShow)

        def printPre(self, message='', onlyShow=None):
            self.dropProgress()
            self.addMessage(type='pre', message=message,
                            onlyShow=onlyShow)

        def printDefault(self, message='', onlyShow=None):
            self.dropProgress()
            self.addMessage(type='plain', message=message,
                            onlyShow=onlyShow)

        def printWARNING(self, message, onlyShow=None):
            self.dropProgress()
            self.addMessage(type='warning', message=message,
                            onlyShow=onlyShow)

        def printERROR(self, message='', onlyShow=None):
            self.dropProgress()
            self.addMessage(type='error', message=message,
                            onlyShow=onlyShow)

        def startTask(self, message, progress=False, num=1):
            if progress:
                self.addMessage(type='startTask', message=message, id=num)
                self.addProgress()
            else:
                self.addMessage(type='startTask', message=message, id=num)

        def setTaskNumber(self, number=None):
            self.addMessage(type='taskNumber', message=str(number))

        def endTask(self, result=None, progress_message=None):
            self.addMessage(type='endTask', message=result)
            self.setProgress(100, progress_message)

        def askConfirm(self, message, default="yes"):
            self.addMessage(type='confirm', message=message, default=default)
            ret = self.getAnswer()
            if ret == "":
                return default
            return ret

        def isInteractive(self):
            return True

        def askChoice(self, message, answers=(("yes", "Yes"), ("no", "No"))):
            self.addMessage(type='choice', message="%s|%s" % (
                message,
                ",".join(map(lambda x: "%s(%s)" % (x[0], x[1]), answers))))
            return self.getAnswer()

        def askQuestion(self, message):
            self.addMessage(type='question', message=message)
            return self.getAnswer()

        def askPassword(self, message, twice=False):
            pas_repeat = 2 if twice else 1
            self.addMessage(type='password', message=message,
                            id=pas_repeat)
            return self.getAnswer()

        def beginFrame(self, message=None):
            self.addMessage(type='beginFrame', message=message)

        def endFrame(self):
            self.addMessage(type='endFrame')

        def startGroup(self, message):
            self.addMessage(type='startGroup', message=message)

        def endGroup(self):
            self.addMessage(type='endGroup')

            # def cache(self, param):
            # sid = self.process_dict['sid']
            # self.args[sid] = collections.OrderedDict()

    def startprocess(self, sid, target=None, method=None, method_name=None,
                     auto_delete=False, args_proc=()):
        """ start process """
        pid = self.gen_pid()
        self.add_sid_pid(sid, pid)

        import multiprocessing

        if self.manager is None:
            self.__class__.manager = multiprocessing.Manager()
        # Manager for sending glob_process_dict between watcher and process
        # manager = multiprocessing.Manager()
        self.glob_process_dict[pid] = self.manager.dict()
        self.glob_process_dict[pid]['sid'] = sid
        self.glob_process_dict[pid]['status'] = 0
        self.glob_process_dict[pid]['time'] = ""
        self.glob_process_dict[pid]['answer'] = None
        self.glob_process_dict[pid]['name'] = ""
        self.glob_process_dict[pid]['flag'] = 0
        self.glob_process_dict[pid]['counter'] = 0

        self.glob_frame_list[pid] = self.manager.list()
        self.glob_progress_dict[pid] = self.manager.dict()
        self.glob_table_dict[pid] = self.manager.dict()

        # create object Common and send parameters
        com = target(self.glob_process_dict[pid],
                     self.glob_progress_dict[pid],
                     self.glob_table_dict[pid],
                     self.glob_frame_list[pid], pid)

        if len(com.__class__.__bases__) > 1 and \
                hasattr(com.__class__.__bases__[1], '__init__'):
            com.__class__.__bases__[1].__init__(com)
        # start helper
        com.method_name = method_name
        p = multiprocessing.Process(target=self.target_helper,
                                    args=(com, getattr(com, method)) +
                                         (method_name,) + args_proc)

        self.process_pid[pid] = p
        p.start()
        if auto_delete:
            # start watcher (for kill process on signal)
            watcher = threading.Thread(target=self.watcher_pid_proc,
                                       args=(sid, pid))

            watcher.start()
        return str(pid)

    # wrap all method
    def target_helper(self, com, target_proc, method_name, *args_proc):
        if not os.path.exists(self.pids):
            os.system('mkdir %s' % self.pids)
        # PID_FILE  =  self.pids + '/%d.pid'%com.pid
        import datetime

        dat = datetime.datetime.now()

        com.process_dict['status'] = 1
        com.process_dict['time'] = dat
        # if method_name:
        com.process_dict['method_name'] = method_name
        com.process_dict['name'] = target_proc.__func__.__name__

        try:
            result = target_proc(*args_proc)
        except Exception:
            result = False
            print_exc()
            fd = open(self.log_filename, 'a')
            print_exc(file=fd)
            fd.close()
        try:
            if result is True:
                com.setStatus(0)
                com.writeFile()
            elif result is False:
                if com.getStatus() == 1:
                    com.setStatus(2)
                com.writeFile()
            else:
                if com.getStatus() == 1:
                    com.setStatus(2)
                else:
                    com.setStatus(0)
                com.writeFile()
            try:
                if 0 < com.getProgress() < 100:
                    com.setProgress(0 - com.getProgress())
                if len(com.frame_list):
                    last_message = com.frame_list[len(com.frame_list) - 1]
                    if last_message.type != 'endFrame':
                        com.endFrame()
                else:
                    com.endFrame()
            except IOError:
                pass

        except Exception:
            print_exc()
            fd = open(self.log_filename, 'a')
            print_exc(file=fd)
            fd.close()
            com.endFrame()

    def serv_view_cert_right(self, cert_id, data_path, client_type=None):
        """ rights for the selected certificate """
        try:
            cert_id = int(cert_id)
        except ValueError:
            return ["-2"]
        cert_file = data_path + '/client_certs/%s.crt' % str(cert_id)
        if not os.path.exists(cert_file):
            return ["-1"]
        cert = readFile(cert_file)

        # try:
        import OpenSSL

        certobj = OpenSSL.crypto.load_certificate(
            OpenSSL.SSL.FILETYPE_PEM, cert)
        com = certobj.get_extension(
            certobj.get_extension_count() - 1).get_data()
        groups = com.split(':')[1]
        groups_list = groups.split(',')
        # except:
        # return ['-1']
        results = []
        find_flag = False
        # if group = all and not redefined group all
        if 'all' in groups_list:
            fd = open(self.group_rights, 'r')
            t = fd.read()
            # find all in group_rights file
            for line in t.splitlines():
                if not line:
                    continue
                if line.split()[0] == 'all':
                    find_flag = True
                    break
            if not find_flag:
                result = []
                if client_type == 'console':
                    for meth_list in self.return_conMethod():
                        for right in LoadedMethods.rightsMethods[meth_list[1]]:
                            result.append(right)
                else:
                    for meth_list in self.return_guiMethod():
                        for right in LoadedMethods.rightsMethods[meth_list[1]]:
                            result.append(right)
                result = uniq(result)
                results = result

        if 'all' not in groups_list or find_flag:
            if not os.path.exists(self.group_rights):
                open(self.group_rights, 'w').close()
            with open(self.group_rights) as fd:
                t = fd.read()
                for line in t.splitlines():
                    if not line:
                        continue
                    try:
                        words = line.split(' ', 1)
                        if len(words) < 2:
                            continue
                        # first word in line equal name input method
                        if words[0] in groups_list:
                            methods = words[1].split(',')
                            for i in methods:
                                results.append(i.strip())
                    except IndexError:
                        print 'except IndexError in serv_view_cert_right'
                        continue
            results = uniq(results)

        add_list_rights = []
        del_list_rights = []

        with open(self.rights) as fr:
            t = fr.read()
            for line in t.splitlines():
                words = line.split()
                meth = words[0]
                for word in words:
                    try:
                        word = int(word)
                    except ValueError:
                        continue
                    # compare with certificat number
                    if cert_id == word:
                        # if has right
                        add_list_rights.append(meth)
                    if cert_id == -word:
                        del_list_rights.append(meth)

        results += add_list_rights
        results = uniq(results)

        for method in results:
            if method in del_list_rights:
                results.remove(method)

        if not results:
            results.append("No Methods")
        return results

    def get_lang(self, sid, method_name=""):
        """ get clients lang """
        lang = None
        SIDS_DIR = self.sids
        with self.sid_locker:
            sid_file = SIDS_DIR + "/%d.sid" % int(sid)
            if os.path.exists(sid_file):
                fd = open(sid_file, 'r')
                while True:
                    try:
                        list_sid = pickle.load(fd)
                    except (IOError, KeyError, EOFError):
                        break
                    # if session id found
                    if sid == list_sid[0]:
                        fd.close()
                        lang = list_sid[3]
                        break
                fd.close()
            try:
                if lang.lower() not in ('uk', 'fr', 'ru', 'en'):
                    lang = "en"
            except AttributeError:
                lang = "en"
            import locale

            try:
                lang = locale.locale_alias[lang.lower()]
            except (TypeError, AttributeError, IndexError, KeyError):
                lang = locale.locale_alias['en']
            return lang


def create_symlink(data_path, old_data_path):
    meths = LoadedMethods.conMethods
    path_to_link = '/usr/bin'
    core_wrapper = "/usr/libexec/calculate/cl-core-wrapper"
    #path_to_user_link = '/usr/bin'
    old_symlinks_file = os.path.join(old_data_path, 'conf/symlinks')
    symlinks_file = os.path.join(data_path, 'conf/symlinks')
    if not os.path.exists(os.path.join(data_path, 'conf')):
        try:
            os.makedirs(os.path.join(data_path, 'conf'))
        except OSError:
            print (_("cannot create directory %s")
                   % (os.path.join(data_path, 'conf')))
    if os.path.exists(old_symlinks_file) and not os.path.exists(symlinks_file):
        with open(symlinks_file, 'w') as fd:
            fd.write(readFile(old_symlinks_file))
        os.unlink(old_symlinks_file)
    with open(symlinks_file, 'a') as fd:
        for link in meths:
            link_path = os.path.join(path_to_link, link)
            if os.path.islink(link_path):
                continue
            if os.path.isfile(link_path):
                red = '\033[31m * \033[0m'
                print red + link_path + _(' is a file, not a link!')
                continue
            try:
                if (os.path.islink(link_path) and
                            os.readlink(link_path) != core_wrapper):
                    os.unlink(link_path)
                os.symlink(core_wrapper, link_path)
                fd.write(link_path + '\n')
            except OSError, e:
                print e.message
            print _('Symlink %s created') % link_path

    temp_text_file = ''
    for line in readLinesFile(symlinks_file):
        cmdname = os.path.basename(line)
        if cmdname not in meths.keys() or not line.startswith(path_to_link):
            if os.path.islink(line):
                os.unlink(line)
                print _('Symlink %s deleted') % line
        else:
            temp_text_file += line + '\n'
    fd = open(symlinks_file, 'w')
    fd.write(temp_text_file)
    fd.close()


def initialization(cl_wsdl):
    """ find modules for further added in server class """
    cl_apis = []
    for pack in cl_wsdl:
        if pack:
            module_name = '%s.wsdl_%s' % (pack.replace("-", "."),
                                          pack.rpartition("-")[2])
            import importlib

            cl_wsdl_core = importlib.import_module(module_name)
            try:
                cl_apis.append(cl_wsdl_core.Wsdl)
            except ImportError:
                sys.stderr.write(_("Unable to import %s") % module_name)
    return cl_apis


# Creation of secret key of the client
def new_key_req(key, cert_path, serv_host_name, port):
    from create_cert import (generateRSAKey, makePKey, makeRequest,
                             passphrase_callback)

    rsa = generateRSAKey()
    rsa.save_key(key + '_pub', cipher=None, callback=passphrase_callback)

    pkey = makePKey(rsa)
    pkey.save_key(key, cipher=None, callback=passphrase_callback)

    req = makeRequest(rsa, pkey, serv_host_name, port)
    if not req:
        sys.exit()
    crtreq = req.as_pem()
    crtfile = open(cert_path + '/server.csr', 'w')
    crtfile.write(crtreq)
    crtfile.close()


# delete dublicate from list
def uniq(seq):
    seen = set()
    seen_add = seen.add
    return [x for x in seq if x not in seen and not seen_add(x)]


class WsdlMeta(type):
    """
    Метакласс для создания методов по атрибуту methdos
    """
    datavars = {}

    def __new__(mcs, name, bases, attrs):
        if "methods" in attrs:
            for method in attrs["methods"]:
                attrs[method['method_name']] = mcs.caller_constructor(**method)
                attrs["%s_vars" % method[
                    'method_name']] = mcs.datavars_constructor(**method)
                attrs["%s_view"
                      % method['method_name']] = mcs.view_constructor(**method)
        return type.__new__(mcs, name, bases, attrs)

    @classmethod
    def close_datavars(mcs):
        for dv in WsdlMeta.datavars.values():
            dv.close()

    @classmethod
    def create_info_obj(mcs, **kwargs):
        """
        Создание передаваемой структуры данных для WSDL
        """
        def type_convert(s):
            if "bool" in s:
                return Boolean
            elif "table" in s:
                return Array(Array(String))
            elif "list" in s:
                return Array(String)
            else:
                return String

        d = {}
        d["cl_console_args"] = Array(String)
        if kwargs['datavars'] in WsdlMeta.datavars:
            dv = WsdlMeta.datavars[kwargs['datavars']]
        else:
            dv = DataVars()
            dv.importVariables()
            dv.importVariables('calculate.%s.variables' % kwargs['datavars'])
            dv.defaultModule = kwargs['datavars']
            WsdlMeta.datavars[kwargs['datavars']] = dv

        def group(*args, **kwargs):
            for v in chain(kwargs.get('normal', ()), kwargs.get('expert', ())):
                varname = v.rpartition(".")[2]
                d[varname] = type_convert(dv.getInfo(v).type)

        for gr in kwargs['groups']:
            gr(group)
        # if "brief" in kwargs:
        #if "cl_page_count" not in d:
        if True:
            d["CheckOnly"] = Boolean
        return d

    @classmethod
    def caller_constructor(mcs, **kwargs):
        """
        Конструктор для создания метода-вызова для действия
        """

        def wrapper(self, sid, info):
            # костыль для локализации install
            callback_refresh = (
                self.fixInstallLocalization
                if kwargs['method_name'] == 'install' else lambda dv, sid: True)
            return self.callAction(sid, info, logicClass=kwargs['logic'],
                                   actionClass=kwargs['action'],
                                   method_name=kwargs['method_name'],
                                   callbackRefresh=callback_refresh,
                                   invalidators=kwargs.get('invalidators', None)
                                   )

        wrapper.func_name = kwargs['method_name']
        func = LoadedMethods.core_method(category=kwargs.get('category', None),
                                         title=kwargs['title'],
                                         image=kwargs.get('image', None),
                                         gui=kwargs['gui'],
                                         user=kwargs.get('user', False),
                                         command=kwargs.get('command', None),
                                         rights=kwargs['rights'],
                                         depends=kwargs.get('depends', ()))(
            wrapper)
        if "--start" in sys.argv:
            info_obj = mcs.create_info_obj(**kwargs)
            info_class = type("%sInfo" % kwargs["method_name"], (CommonInfo,),
                              info_obj)
            return rpc(Integer, info_class,
                       _returns=Array(ReturnedMessage))(func)
        else:
            return func

    @classmethod
    def modify_datavars(mcs, dv, data):
        """
        Поменять значения в datavars согласно data
        """
        # установить заданные значения (!) принудительная установка
        for k, v in data.items():
            # если значение функция
            if callable(v):
                v = v(dv)
            else:
                if isinstance(v, (str, unicode)):
                    v = Variable._value_formatter.format(v, dv.Get)
            dv.Set(k.strip('!'), v, force=k.endswith('!'))

    @classmethod
    def view_constructor(mcs, **kwargs):
        """
        Конструктор для создания метода-представления
        """

        def wrapper(self, sid, params):
            dv = self.get_cache(sid, kwargs["method_name"], "vars")
            lang_changed = False
            if kwargs["groups"]:
                def group(*args, **kwargs):
                    if isinstance(kwargs.get('normal', ()), (unicode, str)):
                        raise DataVarsError(_("Wrong normal varaiables list"))
                    if isinstance(kwargs.get('expert', ()), (unicode, str)):
                        raise DataVarsError(_("Wrong expert varaiables list"))

                for gr in kwargs['groups']:
                    gr(group)
            if not dv:
                dv = getattr(self, "%s_vars" % kwargs["method_name"])(
                    params=params)
                if hasattr(params, "clienttype"):
                    if params.clienttype == 'gui' and "guivars" in kwargs:
                        mcs.modify_datavars(dv, kwargs['guivars'])
                    if params.clienttype != 'gui' and "consolevars" in kwargs:
                        mcs.modify_datavars(dv, kwargs['consolevars'])
                    dv.Set('main.cl_client_type', params.clienttype, force=True)
            else:
                # костыль для метода install, который меняет локализацию
                # интрефейса в зависимости от выбранного параметра lang
                if kwargs["method_name"] == 'install':
                    lang_changed = self.fixInstallLocalization(sid, dv)
                    lang = dv.Get('install.os_install_locale_lang')
                    self.set_cache(sid, "install", "lang", lang, smart=False)
                dv.processRefresh()

            self.set_cache(sid, kwargs["method_name"], "vars", dv, smart=False)
            if "brief" in kwargs and "name" in kwargs['brief']:
                brief_label = str(kwargs['brief']['name'])
            else:
                brief_label = None
            if kwargs["groups"]:
                view = ViewInfo(dv, viewparams=params,
                                has_brief="brief" in kwargs,
                                allsteps=lang_changed,
                                brief_label=brief_label)
            else:
                view = ViewInfo()
            return view

        wrapper.func_name = "%s_view" % kwargs['method_name']
        return rpc(Integer, ViewParams, _returns=ViewInfo)(
            catchExcept(kwargs.get("native_error", ()))(wrapper))

    @classmethod
    def datavars_constructor(mcs, **kwargs):
        """
        Конструктор для создания метода описания параметров
        """

        def wrapper(self, dv=None, params=None):
            if not dv:
                _dv = DataVars()
                _dv.importVariables()
                _dv.importVariables(
                    'calculate.%s.variables' % kwargs['datavars'])
                _dv.defaultModule = kwargs['datavars']
                _dv.flIniFile()
                if params and params.help_set:
                    _dv.Set('cl_help_set', "on", force=True)
                if params and params.dispatch_usenew:
                    _dv.Set('cl_dispatch_conf', "usenew", force=True)
                if params and params.conargs:
                    _dv.Set('cl_console_args', params.conargs, force=True)
            else:
                _dv = dv
            # созданием группы переменных из datavars согласно параметрам groups
            for groupfunc in kwargs['groups']:
                groupfunc(_dv.addGroup)
            if not dv:
                mcs.modify_datavars(_dv, kwargs['setvars'])
            # указание brief если нужно
            if "brief" in kwargs:
                _dv.addBrief(
                    next_label=str(kwargs['brief'].get('next', _('Next'))),
                    image=kwargs['brief'].get('image', None))
            return _dv

        return wrapper


class WsdlBase(object):
    """
    Базовый класс для автосоздания методов по описанию methods
    """
    __metaclass__ = WsdlMeta


def clearDataVars(func):
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        finally:
            WsdlMeta.close_datavars()

    return wrapper

class CustomButton(object):
    @classmethod
    def sort_argv(cls, args):
        behavior = []
        condition = None
        for arg in args:
            if callable(arg):
                condition = arg
            else:
                behavior.append(arg)
        return (behavior or None), condition

    @classmethod
    def run_method(cls, method_name, id, label, *args):
        behavior, condition = cls.sort_argv(args)
        return id, label, method_name, "button", behavior, condition

    @classmethod
    def open_method(cls, method_name, id, label, *args):
        behavior, condition = cls.sort_argv(args)
        return id, label, method_name, "button_view", behavior, condition

    @classmethod
    def next_button(cls, id=None, label=None):
        return id, label, None, "button_next"

    class Behavior(object):
        @classmethod
        def link(cls, source=None, target=None):
            return "%s=%s" % (target, source)

        @classmethod
        def linkerror(cls, source=None, target=None):
            return "%s->%s" % (source, target)

        @classmethod
        def setvalue(cls, variable=None, value=None):
            return "%s!=%s" % (variable, value)

