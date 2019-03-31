# osbuild rpm
Export of declarative package data to streamline operating system image creation

This is a Fedora-specific package to create information about operating system
users, groups and content creation instructions like depmod, ldconfig, hwdb, ...
during the RPM build process. The files are placed in `/usr/share/osbuild/` and
are intended to be used to batch-process/update an operating system tree/image in
a minimal, well-defined environment, instead of running scripts from individual
packages.
