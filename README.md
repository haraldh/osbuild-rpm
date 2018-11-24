# osbuild
Export of declarative package data to streamline operating system image creation

This is a Fedora-specific package to create information about operating systme
users, groups and content creation instructions during the RPM build process.
The files are placed in /usr/share/osbuild and are intended to be used to
postprocess/update an operating system tree/image, instead of calling individual
scripts from individual packages.
