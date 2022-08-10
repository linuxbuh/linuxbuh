# Calculate append=skip

Templates for new Calculate Utilities are stored in this directory.

Calculate templates were specifically designed for setting up your system at
any moment, should you be building your own system or simply tuning your
desktop.

Technically templates are files and directories. The properties of these files
are defined in the first header line, while the properties of the directories
are defined in the '.calculate_directory' file header, located inside the
directory. The file you are reading now is a template too, but this one is not
for configuration purposes and therefore will not be processed by utilities:
the ' append=skip' header says the system to skip it. This line is placed at
the beginning of the template file and must start with '# Calculate'.

Here are some more useful header options:
* env=<module> - pick the variables set from the specified module
* merge=package[,package2, ...] - call the configuration event for the package

The templates header may also contain conditionals with variables and
functions. Variables consist of two words or more, underline-separated: the
first part is the name, the second specifies the utility package it belongs
to, the third specifies the action, the fourth, if applicable, is the type of
value.

For instance:

os_install_lvm_set if LVM partitioning is to be used. 'set' in the variable's
name means that the variable returns either 'on' or 'off'.

To list all variables, run 'cl-core-variables-show'.

Functions, unlike variables, have arguments. Here are some examples of
frequently used functions:
* pkg(category/package[:slot]) returns the version of an installed package.
* merge([package]) returns '1' or '' depending on whether the package must be
configured. If the argument is missing, the package name will be fetched from
the name of the template. If the entire system is being set up, this function
will always return 1 anyway. Keep in mind that the merge() function is not a
header option (see above).

As for now, several versions of templates - the same as the Calculate
Utilities' ones, in fact - are supported: 2.0, 2.2, 3.0 and 3.1. Templates
v2.0 are for server configuration and stored within packages. Templates v2.2
are deprecated and only used for building a system. Templates v3.0 have been
used by the new Calculate installer since CL12. Templates v3.1 are now the
current version and will be supported in all utilities packages someday soon.

Whenever you create your own templates based on those, yours will have the
priority over the default ones. Standard paths for storing user-defined
templates are /var/calculate/templates and
/var/calculate/remote/templates. Note that there are also clt template files,
stored directly in /etc.

Please visit this page for more details:
http://www.calculate-linux.org/main/en/calculate_utilities_templates

We hope you enjoy using Calculate Linux!

