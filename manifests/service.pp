# == Class: named::service
#
# This is a helper class that serves to control the named service and
# has been isolated to make the overall logic more understandable.
#
# == Parameter ==
#
# [*chroot*]
# Type: Boolean
# Default: true
#   Whether or not to run BIND in a chroot jail.
#
# == Authors ==
#
# * Trevor Vaughan - tvaughan@onyxpoint.com
#
class named::service (
  $chroot = true,
  $chroot_path = $::named::params::chroot_path
) {

  validate_bool($chroot)
  if !empty($chroot_path) { validate_absolute_path($chroot_path) }

  if $chroot {
    if $::operatingsystem in ['RedHat','CentOS'] {
      if (versioncmp($::operatingsystemmajrelease,'7') < 0) {
        $svcname = 'named'
      }
      else {
        $svcname = 'named-chroot'
      }
    }
    else {
      fail("The named::service class does not yet support ${::operatingsystem}")
    }

    if !$::selinux_enforced {
      Package['bind-chroot'] -> Service['named']
    }
  }
  else {
    $svcname = 'named'

    Package['bind'] -> Service['named']
  }

  # Work-around for https://bugzilla.redhat.com/show_bug.cgi?id=1278082
  if $::operatingsystem in ['RedHat','CentOS'] and versioncmp($::operatingsystemmajrelease,'7') >= 0 {
    file { '/usr/lib/systemd/system/named-chroot.service':
      ensure  => present,
      content => template('named/named-chroot.service.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Service['named']
    }
  }

  service { 'named':
    ensure     => 'running',
    name       => $svcname,
    enable     => true,
    hasstatus  => true,
    hasrestart => true
  }

  compliance_map()
}
