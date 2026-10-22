# @summary Configures a caching nameserver.
#
# You will need to call named::caching::forwarders to make it useful.
#
# There is also named::caching::root_hints which allows you to set the entire
# contents of the 'named.ca' hint file.
#
# If you want something other than the defaults provided here, use the main
# named class.
#
# @param chroot_path
#   The path to the chroot location.
#
#   * Has no effect if SELinux is enforcing.
#   * Defaults to `named::chroot_path` per module Hiera data.
#
# @param working_dir_owner
#   The owner of the BIND working directory: `/var/named`, or `var/named`
#   inside the chroot
#
#   * Defaults to `named::working_dir_owner` per module Hiera data.
#
# @param working_dir_group
#   The group of the BIND working directory
#
#   * Defaults to `named::working_dir_group` per module Hiera data.
#
# @param working_dir_mode
#   The mode of the BIND working directory
#
#   * BIND 9.16 and later require it to be writable by the `named` group
#   * Defaults to `named::working_dir_mode` per module Hiera data.
#
# @param data_dir_owner
#   The owner of the `data` directory under the BIND working directory
#
#   * Defaults to `named::data_dir_owner` per module Hiera data.
#
# @param data_dir_group
#   The group of the `data` directory under the BIND working directory
#
#   * Defaults to `named::data_dir_group` per module Hiera data.
#
# @param data_dir_mode
#   The mode of the `data` directory under the BIND working directory
#
#   * Defaults to `named::data_dir_mode` per module Hiera data.
#
# @author https://github.com/simp/pupmod-simp-named/graphs/contributors
#
class named::caching (
  Stdlib::Absolutepath $chroot_path,
  String[1]            $working_dir_owner,
  String[1]            $working_dir_group,
  Stdlib::Filemode     $working_dir_mode,
  String[1]            $data_dir_owner,
  String[1]            $data_dir_group,
  Stdlib::Filemode     $data_dir_mode,
) {
  if defined(Class['named']) {
    fail('You cannot include both ::named and ::named::caching')
  }

  simplib::assert_metadata($module_name)

  # Some trickery to use common file resources for chrooted/non chrooted
  # caching files
  $selinux = str2bool($facts['os']['selinux']['enforced'])
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
    chroot            => !empty($_chroot_path),
    chroot_path       => $chroot_path,
    working_dir_owner => $working_dir_owner,
    working_dir_group => $working_dir_group,
    working_dir_mode  => $working_dir_mode,
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

  file { "${_chroot_path}/var/named":
    ensure => 'directory',
    owner  => $working_dir_owner,
    group  => $working_dir_group,
    mode   => $working_dir_mode,
    before => Class['named::service']
  }

  file { "${_chroot_path}/var/named/data":
    ensure => 'directory',
    owner  => $data_dir_owner,
    group  => $data_dir_group,
    mode   => $data_dir_mode,
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
} }
