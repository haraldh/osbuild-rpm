Name:           osbuild
Version:        1
Release:        1%{?dist}
Summary:        Export structured data to streamline the creation of operating system images
License:        ASL2.0
URL:            https://github.com/fabrix/%{name}
Source0:        https://github.com/fabrix/%{name}/archive/%{name}-%{version}.tar.gz
BuildRequires:  lua-json

%description
Export structured data from software packages to streamline the creation,
update, factory-reset of operating system images.

%prep
%setup -q

%install
install -d %{buildroot}%{_datarootdir}/osbuild
install -d %{buildroot}%{_prefix}/lib/rpm/macros.d
install macros.osbuild %{buildroot}%{_prefix}/lib/rpm/macros.d
install -d %{buildroot}%{_prefix}/lib/rpm/lua/osbuild
install JSON.lua %{buildroot}%{_prefix}/lib/rpm/lua/osbuild
install osbuild.lua %{buildroot}%{_prefix}/lib/rpm/lua/osbuild

%files
%{_datarootdir}/osbuild
%{_prefix}/lib/rpm/macros.d/macros.osbuild
%{_prefix}/lib/rpm/lua/osbuild
%{_prefix}/lib/rpm/lua/osbuild/osbuild.lua
%{_prefix}/lib/rpm/lua/osbuild/JSON.lua

%changelog
* Fri Nov 23 2018 <kay@redhat.com> 1-1
- osbuild 1
