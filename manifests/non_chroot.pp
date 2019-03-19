# This class configures named for execution on a system using selinux.
# It pulls all config files from rsync.
#
# It is meant to be called from named directly.
#
# @param bind_dns_rsync
#   The target under #
#   /var/simp/environments/{environment}/rsync/{os}/{maj_version}/bind_dns
#   from which to fetch all BIND DNS content.
#
# @author https://github.com/simp/pupmod-simp-named/graphs/contributors
#
class named::non_chroot (
  String                  $bind_dns_rsync = $::named::bind_dns_rsync,
  String                  $rsync_source   = "bind_dns_${::named::bind_dns_rsync}_${::environment}_${facts['os']['name']}_${facts['os']['release']['major']}/named",
  String                  $rsync_server   = $::named::rsync_server,
  Stdlib::Compat::Integer $rsync_timeout  = $::named::rsync_timeout
){
  assert_private()

  include '::rsync'

  $_rsync_user = "bind_dns_${::named::bind_dns_rsync}_rsync_${::environment}_${facts['os']['name']}_${facts['os']['release']['major']}"

  if ( str2bool($::selinux_enforced) != true ) {
    fail( 'named::non_chroot must be used with selinux!')
  }

  simplib::validate_net_list($rsync_server)

  file { '/etc/named.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    notify  => Rsync['named_etc'],
    require => Package['bind']
  }

  file { '/var/named':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'named',
    mode    => '0750',
    notify  => Rsync['named'],
    require => Package['bind']
  }

  rsync { 'named':
    user     => $_rsync_user,
    password => simplib::passgen($_rsync_user),
    source   => "${rsync_source}/var/named",
    target   => '/var',
    server   => $rsync_server,
    timeout  => $rsync_timeout,
    notify   => Class['named::service']
  }

  rsync { 'named_etc':
    user     => $_rsync_user,
    password => simplib::passgen($_rsync_user),
    source   => "${rsync_source}/etc/*",
    target   => '/etc',
    server   => $rsync_server,
    timeout  => $rsync_timeout,
    notify   => Class['named::service']
  }
}
