Summary: Named/Bind Puppet Module
Name: pupmod-named
Version: 4.2.0
Release: 9
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-iptables >= 4.1.0-3
Requires: pupmod-rsync >= 4.0.0-14
Requires: pupmod-simpcat >= 4.0.0-0
Requires: puppet >= 3.3.0
Requires: simp_bootstrap >= 4.1.0-1
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-named-test
Requires: pupmod-onyxpoint-compliance_markup

Prefix:"/etc/puppet/environments/simp/modules"

%description
This Puppet module provides the capability to configure either a chrooted named
process or a caching nameserver.

Rsync is used for the configuration files.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/named

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/named
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/named

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/named

%files
%defattr(0640,root,puppet,0750)
/etc/puppet/environments/simp/modules/named

%post
#!/bin/sh

if [ -d /etc/puppet/environments/simp/modules/named/plugins ]; then
  /bin/mv /etc/puppet/environments/simp/modules/named/plugins /etc/puppet/environments/simp/modules/named/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Tue Feb 23 2016 Ralph Wright <ralph.wright@onyxpoint.com> - 4.2.0-9
- Added compliance function support

* Thu Dec 03 2015 Chris Tessmer <chris.tessmer@onyxpoint.com> - 4.2.0-8
- `named::non_chroot` will now intentionally fail (with an informative message)
  if included when selinux is not enforcing

* Mon Nov 09 2015 Chris Tessmer <chris.tessmer@onypoint.com> - 4.2.0-7
- migration to simplib and simpcat (lib/ only)

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-6
- Changed puppet-server requirement to puppet

* Mon Sep 15 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-5
- Restricted the rsync of materials in /etc in non-chroot so that
  users can't accidentally destroy the permissions on /etc itself.

* Mon Jul 21 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-4
- Updated to provide the appropriate pointers to the new rsync layout.

* Wed Jul 02 2014 Kendall Moore <kmoore@keywcorp.com> - 4.2.0-3
- Updated caching nameserver to be SELinux compatible.

* Thu Jun 26 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-2
- Added additional compatiblity with RHEL7 given the new named service
  for chroot is called 'named-chroot'.

* Sun Jun 22 2014 Kendall Moore <kmoore@keywcorp.com> - 4.2.0-1
- Removed MD5 file checksums for FIPS compliance.

* Fri Jun 20 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-1
- Ensure that $named::auth_users is an Array.

* Wed Apr 16 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.2.0-0
- The caching-nameserver package has been rolled into bind; removing caching-nameserver
  removes the bind package. Caching-nameserver no longer ensured absent.

* Tue Apr 08 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.2.0-0
- Made several adjustments to make the rsync space more clear.
- The chroot and non_chroot spaces now reference rsync/default (by
  default), but 'default' can be changed in case you want a DNS server
  with a whole different configuration.

* Mon Mar 03 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-1
- Refactored manifests to pass all lint tests.
- Added rspec tests for test coverage.

* Wed Feb 12 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-0
- Converted all boolean strings to true booleans for Puppet 3
  migration.

* Fri Oct 25 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.0.0-2
- Updated all 'source' File parameters to have 'modules' in their path
  for Puppet 3 compatibility.

* Mon Oct 07 2013 Kendall Moore <kmoore@keywcorp.com> 4.0.0-1
- Updated all erb templates to properly scope variables.

* Thu May 02 2013 Trevor Vaughan <tvaughan@onyxpoint.com> 4.0.0-0
- Work done with Kendall Moore <kmoore@keywcorp.com>
- Modify the named module so that named does not install into a chroot jail if
  SELinux is enabled since these two states are incompatible (and unnecessary).

* Mon Feb 25 2013 Maintenance
2.0-6
- Added a call to $::rsync_timeout to the rsync call since it is now required.

* Wed Apr 11 2012 Maintenance
2.0.0-5
- Moved mit-tests to /usr/share/simp...
- Fixed an issue with the caching DNS server where requisite files
  were not being placed which was causing the DNS server to fail.
- Updated pp files to better meet Puppet's recommended style guide.

* Mon Mar 12 2012 Maintenance
2.0.0-4
- Updated tests for this module to work properly.
- Improved test stubs.
- Discovered that the DHCP caching nameserver was not putting the config file
  in the correct location. Fixed.

* Mon Jan 30 2012 Maintenance - 2.0.0-3
- Added test stubs.

* Mon Dec 19 2011 Maintenance - 2.0.0-2
- Updated the spec file to not require a separate file list.
- Updated the caching nameserver to work with the chrooted bind package since
  the caching-nameserver package is removed from RHEL6 and both work with the
  chrooted package.

* Fri Feb 11 2011 Maintenance - 2.0.0-1
- The named module now expects to have an associated rsync space that is
  password protected.
- Changed all instances of defined(Class['foo']) to defined('foo') per the
  directions from the Puppet mailing list.
- Updated to use rsync native type
- Updated to use concat_build and concat_fragment types.

* Tue Jan 11 2011 Maintenance
2.0.0-0
- Refactored for SIMP-2.0.0-alpha release

* Tue Oct 26 2010 Maintenance - 1-2
- Converting all spec files to check for directories prior to copy.

* Mon Oct 04 2010 Maintenance
1.0-1
- Addition of caching nameserver capability.

* Fri May 21 2010 Maintenance
1.0-0
- Code refactor and doc update.
