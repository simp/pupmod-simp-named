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
  $chroot_path = '/var/named/chroot'
) {
  include 'named::service'

  $selinux_enabled = (str2bool($::selinux_enforced)) or (empty($chroot_path) and ! str2bool($::selinux_enforced))
  $l_path = $selinux_enabled ? {
    true  => '',
    false => $chroot_path
  }

  if $::operatingsystem in ['RedHat','CentOS'] {
    $rfc_1912_zonefile = $::lsbmajdistrelease ? {
      '5'     => "$l_path/etc/named.rfc1912.zones",
      default => '/etc/named.rfc1912.zones'
    }
  }
  else {
    $rfc_1912_zonefile = "$l_path/etc/named.rfc1912.zones"
  }

  concat_build { 'named_caching':
    order  => ['header', '*.forward', 'footer'],
    target => "$l_path/etc/named_caching.forwarders"
  }

  concat_fragment { 'named_caching+header':
    content => 'forwarders {'
  }

  concat_fragment { 'named_caching+footer':
    content => '};'
  }

  if !empty($l_path) {
    file { '/etc/named.conf':
      ensure => 'symlink',
      target => "$l_path/etc/named.conf",
      notify => Service['named']
    }
  }

  file { $rfc_1912_zonefile:
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    source  => 'puppet:///modules/named/chroot/etc/named.rfc1912.zones',
    notify  => Service['named']
  }

  file { "$l_path/var/named/localdomain.zone":
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    source  => 'puppet:///modules/named/chroot/var/named/localdomain.zone',
    notify  => Service['named']
  }

  file { "$l_path/var/named/localhost.zone":
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    source  => 'puppet:///modules/named/chroot/var/named/localhost.zone',
    notify  => Service['named']
  }

  file { "$l_path/var/named/named.broadcast":
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    source  => 'puppet:///modules/named/chroot/var/named/named.broadcast',
    notify  => Service['named']
  }

  file { "$l_path/var/named/named.ip6.local":
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    source  => 'puppet:///modules/named/chroot/var/named/named.ip6.local',
    notify  => Service['named']
  }

  file { "$l_path/var/named/named.local":
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    source  => 'puppet:///modules/named/chroot/var/named/named.local',
    notify  => Service['named']
  }

  file { "$l_path/var/named/named.zero":
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0644',
    source  => 'puppet:///modules/named/chroot/var/named/named.zero',
    notify  => Service['named']
  }

  file { "$l_path/etc/named.conf":
    ensure   => 'file',
    owner    => 'root',
    group    => 'named',
    mode     => '0640',
    content  => template('named/named.caching.conf.erb'),
    notify   => Service['named']
  }

  file { "$l_path/etc/named_caching.forwarders":
    owner     => 'root',
    group     => 'named',
    mode      => '0640',
    notify    => Service['named'],
    subscribe => Concat_build['named_caching'],
    audit     => content
  }

  # Only install bind-chroot if we are using a chroot jail
  if ! $selinux_enabled {
    package { 'bind-chroot':
      ensure => 'latest',
      notify => Service['named']
    }
  }
}
