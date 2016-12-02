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
  $nchroot        = $::named::chroot_path,
  $bind_dns_rsync = $::named::bind_dns_rsync,
  $rsync_source   = "bind_dns_${::named::bind_dns_rsync}_${::environment}/named/",
  $rsync_server   = $::named::rsync_server,
  $rsync_timeout  = $::named::rsync_timeout
) {
  assert_private()

  include '::rsync'

  if !empty($nchroot) { validate_absolute_path($nchroot) }
  validate_string($bind_dns_rsync)
  validate_net_list($rsync_server)
  validate_integer($rsync_timeout)

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

  file { "${nchroot}/var/named":
    ensure => 'directory',
    owner  => 'root',
    group  => 'named',
    mode   => '0750',
    notify => Rsync['named']
  }

  file { '/etc/named.conf':
    ensure => "${nchroot}/etc/named.conf"
  }

  rsync { 'named':
    user             => "bind_dns_${bind_dns_rsync}_rsync_${::environment}",
    password         => passgen("bind_dns_${bind_dns_rsync}_rsync_${::environment}"),
    source           => $rsync_source,
    target           => $nchroot,
    server           => $rsync_server,
    timeout          => $rsync_timeout,
    preserve_devices => true,
    exclude          => [ 'localtime', 'var/run', 'proc' ],
    notify           => Class['named::service']
  }
}
