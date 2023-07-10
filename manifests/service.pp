# @summary A helper class that serves to control the named service and has been
# isolated to make the overall logic more understandable.
#
# @param chroot
#   Whether or not to run BIND in a chroot jail.
#
# @param chroot_path
#   @see named::chroot_path
#
# @author https://github.com/simp/pupmod-simp-named/graphs/contributors
#
class named::service (
  Boolean              $chroot      = true,
  Stdlib::Absolutepath $chroot_path = $::named::chroot_path
) {
  assert_private()

  if $chroot {
    if $facts['os']['name'] in ['RedHat','CentOS','OracleLinux','Rocky'] {
      if (versioncmp($facts['os']['release']['major'],'7') < 0) {
        $svcname = 'named'
      }
      else {
        $svcname = 'named-chroot'
      }
    }
    else {
      fail("The named::service class does not yet support ${facts['os']['name']}")
    }
  }
  else {
    $svcname = 'named'
  }

  # Work-around for https://bugzilla.redhat.com/show_bug.cgi?id=1278082
  if $facts['os']['name'] in ['RedHat','CentOS','OracleLinux'] and versioncmp($facts['os']['release']['major'],'7') >= 0 {
    # Override with a full replacement file, as we are changing the
    # Unit Requires and After lists and changing the Service Type
    # from forking to the default (simple).
    file { '/etc/systemd/system/named-chroot.service':
      ensure  => 'file',
      content => template('named/named-chroot.service.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Service[$svcname]
    }

    exec { 'named-systemctl-daemon-reload':
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
