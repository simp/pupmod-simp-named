# @summary Configures named in a chroot jail for execution on a system.
#
# It pulls all config files from rsync.
#
# It is meant to be called from named directly.
#
# @param nchroot
#   The Chroot jail for named. This should probably not be changed.
#
# @param bind_dns_rsync
#   The target under the /var/simp/environments/{environment}/rsync/{os}/{maj_version}/bind_dns from which to fetch all
#   BIND DNS content.
#
# @param rsync_source
#   The source from which the module will pull its files on the rsync server
#
# @param rsync_server
#   The rsync server from which to pull the named configuration.
#
# @param rsync_timeout
#   The timeout when connecting to the rsync server.
#
# @param working_dir_owner
#   The owner of the BIND working directory
#
# @param working_dir_group
#   The group of the BIND working directory
#
# @param working_dir_mode
#   The mode of the BIND working directory
#
# @param data_dir_owner
#   The owner of the `data` directory under the BIND working directory
#
# @param data_dir_group
#   The group of the `data` directory under the BIND working directory
#
# @param data_dir_mode
#   The mode of the `data` directory under the BIND working directory
#
# @param slaves_dir_owner
#   The owner of the `slaves` directory under the BIND working directory
#
# @param slaves_dir_group
#   The group of the `slaves` directory under the BIND working directory
#
# @param slaves_dir_mode
#   The mode of the `slaves` directory under the BIND working directory
#
# @author https://github.com/simp/pupmod-simp-named/graphs/contributors
#
class named::chroot (
  Stdlib::Absolutepath $nchroot           = $named::chroot_path,
  String               $bind_dns_rsync    = $named::bind_dns_rsync,
  String               $rsync_source      = "bind_dns_${named::bind_dns_rsync}_${environment}_${facts['os']['name']}_${facts['os']['release']['major']}/named",
  String               $rsync_server      = $named::rsync_server,
  Variant[
    Integer[0],
    Pattern[/\A\d+\z/]
  ]                    $rsync_timeout     = $named::rsync_timeout,
  String[1]            $working_dir_owner = $named::working_dir_owner,
  String[1]            $working_dir_group = $named::working_dir_group,
  Stdlib::Filemode     $working_dir_mode  = $named::working_dir_mode,
  String[1]            $data_dir_owner    = $named::data_dir_owner,
  String[1]            $data_dir_group    = $named::data_dir_group,
  Stdlib::Filemode     $data_dir_mode     = $named::data_dir_mode,
  String[1]            $slaves_dir_owner  = $named::slaves_dir_owner,
  String[1]            $slaves_dir_group  = $named::slaves_dir_group,
  Stdlib::Filemode     $slaves_dir_mode   = $named::slaves_dir_mode,
) {
  assert_private()

  include 'rsync'

  $_rsync_user = "bind_dns_${named::bind_dns_rsync}_rsync_${server_facts['environment']}_${facts['os']['name']}_${facts['os']['release']['major']}"

  simplib::validate_net_list($rsync_server)

  file { $nchroot:
    ensure => 'directory',
    owner  => 'root',
    group  => 'named',
    mode   => '0750'
  }

  file { "${nchroot}/etc":
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    seltype => 'etc_t'
  }

  file { "${nchroot}/var":
    ensure  => 'directory',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    seltype => 'var_t'
  }

  file { "${nchroot}/etc/named.conf":
    ensure => 'file',
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    notify => Rsync['named']
  }

  file { '/etc/named.conf':
    ensure => "${nchroot}/etc/named.conf"
  }

  rsync { 'named':
    user             => $_rsync_user,
    password         => simplib::passgen($_rsync_user),
    source           => "${rsync_source}/*",
    target           => $nchroot,
    server           => $rsync_server,
    timeout          => $rsync_timeout,
    preserve_devices => true,
    exclude          => ['localtime', 'var/run', 'proc'],
    notify           => Class['named::service']
  }

  # These are applied after the rsync so that they override the copies from
  # the rsync server.
  file { "${nchroot}/var/named":
    ensure  => 'directory',
    owner   => $working_dir_owner,
    group   => $working_dir_group,
    mode    => $working_dir_mode,
    require => Rsync['named'],
  }

  file { "${nchroot}/var/named/data":
    ensure  => 'directory',
    owner   => $data_dir_owner,
    group   => $data_dir_group,
    mode    => $data_dir_mode,
    require => Rsync['named'],
  }

  file { "${nchroot}/var/named/slaves":
    ensure  => 'directory',
    owner   => $slaves_dir_owner,
    group   => $slaves_dir_group,
    mode    => $slaves_dir_mode,
    require => Rsync['named'],
  }
}
