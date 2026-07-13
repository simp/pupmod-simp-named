# @summary A helper class that serves to control the named service and has been
# isolated to make the overall logic more understandable.
#
# @param chroot
#   Whether or not to run BIND in a chroot jail.
#
# @param chroot_path
#   @see named::chroot_path
#
# @param chroot_service_name
#   The name of the service when running in a chroot jail.
#
#   * Value in module data
#
# @param non_chroot_service_name
#   The name of the service when not running in a chroot jail.
#
#   * Value in module data
#
# @param use_systemd
#   Whether to use the systemd service override file.
#
#   * Value in module data
#
# @author https://github.com/simp/pupmod-simp-named/graphs/contributors
#
class named::service (
  Boolean              $chroot                 = true,
  Stdlib::Absolutepath $chroot_path            = $named::chroot_path,
  String[1]            $chroot_service_name,
  String[1]            $non_chroot_service_name,
  Boolean              $use_systemd,
) {
  assert_private()

  $svcname = $chroot ? {
    true  => $chroot_service_name,
    false => $non_chroot_service_name,
  }

  # Work-around for https://bugzilla.redhat.com/show_bug.cgi?id=1278082
  if $use_systemd {
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
