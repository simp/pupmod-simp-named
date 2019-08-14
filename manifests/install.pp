# @summary Installs the appropriate packages for BIND based on the chroot status
#
# @private
#
# @param ensure
#   The `package` ensure setting for installed packages
#
#   @see https://docs.puppet.com/puppet/latest/reference/type.html#package-attribute-ensure
#
# @param chroot
#   Whether or not to use a chroot jail
#
# @param chroot_path
#   The path to the chroot jail
class named::install (
  Boolean              $chroot      = true,
  Stdlib::Absolutepath $chroot_path = $::named::chroot_path,
  String               $ensure      = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
){
  assert_private()

  package { 'bind': ensure => $ensure }
  package { 'bind-libs': ensure => $ensure }

  if $chroot {
    package { 'bind-chroot': ensure => $ensure }
  }
  else {
    package { 'bind-chroot': ensure => 'absent' }
  }

  file { '/var/named':
    ensure => 'directory',
    owner  => 'root',
    group  => 'named',
    mode   => '0750'
  }

  group { 'named':
    ensure    => 'present',
    allowdupe => false,
    gid       => '25'
  }

  user { 'named':
    ensure     => 'present',
    allowdupe  => false,
    uid        => '25',
    gid        => '25',
    home       => '/var/named',
    membership => 'inclusive',
    shell      => '/sbin/nologin'
  }
}
