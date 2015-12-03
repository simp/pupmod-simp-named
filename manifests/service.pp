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
  $chroot = true
) {
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

  service { 'named':
    ensure     => 'running',
    name       => $svcname,
    enable     => true,
    hasstatus  => true,
    hasrestart => true
  }

  validate_bool($chroot)
}
