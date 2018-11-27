# rpmbuild --define "_sourcedir $(pwd)" --define "_specdir $(pwd)" --define "_builddir $(pwd)" --define "_srcrpmdir $(pwd)" --define "_rpmdir $(pwd)" -ba test.spec && rpm -qp --scripts noarch/*.rpm && rpm -qp --provides  noarch/*.rpm

Name:           test
Version:        1
Release:        1
Summary:        Test package
License:        MIT
BuildArch:      noarch

%define GROUPNAME1 group1
%define USERNAME1  user1-baz

%osbuild_groupadd -g 11 %{GROUPNAME1}
%osbuild_groupadd -g 12 group2
%osbuild_groupadd -g 13 group3
%osbuild_groupadd group4
%osbuild_useradd -g group1 -G group3,group4 -u 100 -d /var/user1 -s /sbin/nologin -c %{quote:User 1} %{USERNAME1}
%osbuild_useradd -g group2 -G group3,group4 -d /var/user$2 -s /sbin/nologin -c %{quote:User 2} user2

%description
This is the test package.

%package sub
Summary:         Test sub package
%osbuild_groupadd -S sub -g 21 subgroup1
%description sub
This is the sub package.

%package -n foo
Summary:         Foo package
%osbuild_groupadd -n foo -g 31 foo1
%description -n foo
This is the foo package.

%pre
%osbuild_pre

%pre sub
%osbuild_pre -S sub

%pre -n foo
%osbuild_pre -n foo

%prep

%build

%install
%osbuild_install
%osbuild_install -n foo
%osbuild_install -S sub

%files
%osbuild_files

%files sub
%osbuild_files -S sub

%files -n foo
%osbuild_files -n foo
