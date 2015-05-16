# == Class: named::chroot
#
# This class configures named in a chroot jail for execution on a system.
# It pulls all config files from rsync.
#
# It is meant to be called from named directly.
#
# == Parameters
#
# [*nchroot*]
#   Type: Absolute Path
#   Default: $::named::chroot_path
#     The Chroot jail for named. This should probably not be changed.
#
# [*bind_dns_rsync*]
#   Type: String
#   Default: $::named::bind_dns_rsync
#     The target under the /srv/rsync/bind_dns from which to fetch all
#     BIND DNS content.
#
# [*rsync_server*]
#   Type: FQDN
#   Default: hiera(rsync::server)
#     The rsync server from which to pull the named configuration.
#
# [*rsync_timeout*]
#   Type: Integer
#   Default: hiera(rsync::timeout)
#     The timeout when connecting to the rsync server.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class named::chroot (
  $nchroot = $::named::chroot_path,
  $bind_dns_rsync = $::named::bind_dns_rsync,
  $rsync_server = $::named::rsync_server,
  $rsync_timeout = $::named::rsync_timeout
) {
  include 'named'

  file { $nchroot:
    ensure  => 'directory',
    owner   => 'root',
    group   => 'named',
    mode    => '0750',
    require => Package['bind-chroot']
  }

  file { "${nchroot}/etc/named.conf":
    ensure   => 'present',
    owner    => 'root',
    group    => 'named',
    mode     => '0640',
    notify   => Rsync['named'],
    require  => Package['bind-chroot']
  }

  file { "${nchroot}/var/named":
    ensure  => 'directory',
    owner   => 'root',
    group   => 'named',
    mode    => '0750',
    notify  => Rsync['named'],
    require => Package['bind-chroot']
  }

  file { '/etc/named.conf':
    ensure  => "${nchroot}/etc/named.conf",
    require => Package['bind-chroot']
  }

  package { 'bind-chroot': ensure => 'latest' }

  rsync { 'named':
    user             => "bind_dns_${bind_dns_rsync}_rsync",
    password         => passgen("bind_dns_${bind_dns_rsync}_rsync"),
    source           => "bind_dns_${bind_dns_rsync}/named/",
    target           => $nchroot,
    server           => $rsync_server,
    timeout          => $rsync_timeout,
    preserve_devices => true,
    exclude          => [ 'localtime', 'var/run', 'proc' ],
    notify           => Service['named']
  }

  validate_absolute_path($nchroot)
}
