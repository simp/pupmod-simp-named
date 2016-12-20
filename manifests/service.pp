# This is a helper class that serves to control the named service and
# has been isolated to make the overall logic more understandable.
#
# @param chroot
#   Whether or not to run BIND in a chroot jail.
#
# @author Trevor Vaughan - tvaughan@onyxpoint.com
#
class named::service (
  Boolean              $chroot      = true,
  Stdlib::Absolutepath $chroot_path = $::named::chroot_path
) {
  assert_private()

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
  }
  else {
    $svcname = 'named'
  }

  # Work-around for https://bugzilla.redhat.com/show_bug.cgi?id=1278082
  if $::operatingsystem in ['RedHat','CentOS'] and versioncmp($::operatingsystemmajrelease,'7') >= 0 {
    file { '/usr/lib/systemd/system/named-chroot.service':
      ensure  => 'file',
      content => template('named/named-chroot.service.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Service[$svcname]
    }

    exec { 'systemctl-daemon-reload':
      command     => 'systemctl daemon-reload',
      refreshonly => true,
      path        => '/bin:/usr/bin:/usr/local/bin',
      before      => Service[$svcname]
    }
  }

  service { $svcname:
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true
  }

}
