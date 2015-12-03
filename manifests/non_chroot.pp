# == Class: named::non_chroot
#
# This class configures named for execution on a system using selinux.
# It pulls all config files from rsync.
#
# It is meant to be called from named directly.
#
# [*bind_dns_rsync*]
#   Type: String
#   Default: $::named::bind_dns_rsync
#     The target under #
#     hiera('rsync::base','/srv/rsync/$::operatingsystem/$::operatingsystemmajrelease')/bind_dns
#     from which to fetch all BIND DNS content.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
# * Kendall Moore <kmoore@keywcorp.com>
# * Chris Tessmer <chirs.tessmer@onyxpoint.com
#
class named::non_chroot (
  $bind_dns_rsync = $::named::bind_dns_rsync,
  $rsync_server = $::named::rsync_server,
  $rsync_timeout = $::named::rsync_timeout
){
  if ( str2bool($::selinux_enforced) != true ) {
    fail( 'named::non_chroot must be used with selinux!')
  }

  include 'named'

  file { '/etc/named.conf':
    ensure  => 'present',
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

  package { 'bind-chroot':
    ensure => 'absent'
  }

  rsync { 'named':
    user     => "bind_dns_${bind_dns_rsync}_rsync",
    password => passgen("bind_dns_${bind_dns_rsync}_rsync"),
    source   => "bind_dns_${bind_dns_rsync}/named/var/named",
    target   => '/var',
    server   => $rsync_server,
    timeout  => $rsync_timeout,
    notify   => Service['named']
  }

  rsync { 'named_etc':
    user     => "bind_dns_${bind_dns_rsync}_rsync",
    password => passgen("bind_dns_${bind_dns_rsync}_rsync"),
    source   => "bind_dns_${bind_dns_rsync}/named/etc/*",
    target   => '/etc',
    server   => $rsync_server,
    timeout  => $rsync_timeout,
    notify   => Service['named']
  }
}
