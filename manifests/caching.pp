# This class configures a caching nameserver.
# You will need to call named::caching::forwarders to make it useful.
#
# There is also named::caching::root_hints which allows you to set the entire
# contents of the 'named.ca' hint file.
#
# If you want something other than the defaults provided here, use the main
# named class.
#
# @author https://github.com/simp/pupmod-simp-named/graphs/contributors
#
class named::caching(
  Stdlib::Absolutepath $chroot_path = $::named::params::chroot_path
) inherits ::named::params {

  if defined(Class['named']) {
    fail('You cannot include both ::named and ::named::caching')
  }

  simplib::assert_metadata($module_name)

  # Some trickery to use common file resources for chrooted/non chrooted
  # caching files
  $selinux = str2bool($::selinux_enforced)
  $_chroot_path = $selinux ? {
    true  => '',
    false => $chroot_path
  }

  # Installation and service
  if !empty($_chroot_path) {
    file_line { 'bind_chroot':
      path      => '/etc/sysconfig/named',
      line      => "OPTIONS=\"-t ${_chroot_path}\"",
      before    => Class['named::service'],
      subscribe => Package['bind-chroot']
    }
    file { '/etc/named.conf':
      ensure => 'symlink',
      target => "${_chroot_path}/etc/named.conf",
      notify => Class['named::service']
    }
  }
  class { 'named::install':
    chroot      => !empty($_chroot_path),
    chroot_path => $chroot_path
  }
  class { 'named::service':
    chroot      => !empty($_chroot_path),
    chroot_path => $chroot_path
  }
  Class['named::install'] -> Class['named::caching']
  Class['named::install'] ~> Class['named::service']

  concat { 'named_caching':
    order  => numeric,
    notify => Class['named::service'],
    owner  => 'root',
    group  => 'named',
    mode   => '0640',
    path   => "${_chroot_path}/etc/named_caching.forwarders"
  }

  concat_fragment { 'named_caching+header':
    order   => 0,
    target  => 'named_caching',
    content => 'forwarders {'
  }

  concat_fragment { 'named_caching+footer':
    order   => 100,
    target  => 'named_caching',
    content => '};'
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


}
