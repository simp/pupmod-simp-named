# == Class: named::caching
#
# This class configures a caching nameserver.
# You will need to call named::caching::forwarders to make it useful.
#
# There is also named::caching::root_hints which allows you to set the entire
# contents of the 'named.ca' hint file.
#
# If you want something other than the defaults provided here, use the main
# named class.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class named::caching(
  $chroot_path = $::named::params::chroot_path
) inherits ::named::params {

  if defined(Class['named']) {
    fail('You cannot include both ::named and ::named::caching')
  }

  if !empty($chroot_path) { validate_absolute_path($chroot_path) }

  $selinux_enabled = (str2bool($::selinux_enforced)) or (empty($chroot_path) and ! str2bool($::selinux_enforced))
  $_chroot_path = $selinux_enabled ? {
    true  => '',
    false => $chroot_path
  }

  class { '::named::service':
    chroot      => !empty($_chroot_path),
    chroot_path => $_chroot_path
  }

  simpcat_build { 'named_caching':
    order  => ['header', '*.forward', 'footer'],
    target => "${_chroot_path}/etc/named_caching.forwarders"
  }

  simpcat_fragment { 'named_caching+header':
    content => 'forwarders {'
  }

  simpcat_fragment { 'named_caching+footer':
    content => '};'
  }

  if !empty($_chroot_path) {
    file { '/etc/named.conf':
      ensure => 'symlink',
      target => "${_chroot_path}/etc/named.conf",
      notify => Class['named::service']
    }
  }

  file { "${_chroot_path}/etc/named.rfc1912.zones":
    ensure => 'file',
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    source => 'puppet:///modules/named/chroot/etc/named.rfc1912.zones',
    notify => Class['named::service']
  }

  file { "${_chroot_path}/var/named/data":
    ensure => 'directory',
    owner  => 'named',
    group  => 'named',
    mode   => '0750',
    before => Class['named::service']
  }

  file { "${_chroot_path}/var/named/localdomain.zone":
    ensure => 'file',
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    source => 'puppet:///modules/named/chroot/var/named/localdomain.zone',
    notify => Class['named::service']
  }

  file { "${_chroot_path}/var/named/localhost.zone":
    ensure => 'file',
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    source => 'puppet:///modules/named/chroot/var/named/localhost.zone',
    notify => Class['named::service']
  }

  file { "${_chroot_path}/var/named/named.broadcast":
    ensure => 'file',
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    source => 'puppet:///modules/named/chroot/var/named/named.broadcast',
    notify => Class['named::service']
  }

  file { "${_chroot_path}/var/named/named.ip6.local":
    ensure => 'file',
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    source => 'puppet:///modules/named/chroot/var/named/named.ip6.local',
    notify => Class['named::service']
  }

  file { "${_chroot_path}/var/named/named.local":
    ensure => 'file',
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    source => 'puppet:///modules/named/chroot/var/named/named.local',
    notify => Class['named::service']
  }

  file { "${_chroot_path}/var/named/named.zero":
    ensure => 'file',
    owner  => 'root',
    group  => 'named',
    mode   => '0644',
    source => 'puppet:///modules/named/chroot/var/named/named.zero',
    notify => Class['named::service']
  }

  file { "${_chroot_path}/etc/named.conf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    content => template('named/named.caching.conf.erb'),
    notify  => Class['named::service']
  }

  file { "${_chroot_path}/etc/named_caching.forwarders":
    owner     => 'root',
    group     => 'named',
    mode      => '0640',
    notify    => Class['named::service'],
    subscribe => Simpcat_build['named_caching'],
    audit     => content
  }

  if !empty($_chroot_path) and !($selinux_enabled) {
    file_line { 'bind_chroot':
      path      => '/etc/sysconfig/named',
      line      => "OPTIONS=\"-t ${_chroot_path}\"",
      before    => Class['named::service'],
      subscribe => Package['bind-chroot']
    }

    class { '::named::install':
      chroot      => true,
      chroot_path => $_chroot_path
    }
  }
  else {
    class { '::named::install':
      chroot      => false,
      chroot_path => '/dev/null'
    }
  }

  Class['named::install'] -> Class['named::caching']
  Class['named::install'] ~> Class['named::service']
}
