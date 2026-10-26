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
#
# @param working_dir_owner
#   The owner of `/var/named` when using a chroot jail
#
# @param working_dir_group
#   The group of `/var/named` when using a chroot jail
#
# @param working_dir_mode
#   The mode of `/var/named` when using a chroot jail
class named::install (
  Boolean              $chroot            = true,
  Stdlib::Absolutepath $chroot_path       = $named::chroot_path,
  String               $ensure            = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  String[1]            $working_dir_owner = $named::working_dir_owner,
  String[1]            $working_dir_group = $named::working_dir_group,
  Stdlib::Filemode     $working_dir_mode  = $named::working_dir_mode,
) {
  assert_private()

  package { 'bind': ensure => $ensure }
  package { 'bind-libs': ensure => $ensure }

  if $chroot {
    package { 'bind-chroot': ensure => $ensure }

    # Without a chroot jail, /var/named is the working directory, and the
    # class that configures it manages it.
    file { '/var/named':
      ensure => 'directory',
      owner  => $working_dir_owner,
      group  => $working_dir_group,
      mode   => $working_dir_mode,
    }
  }
  else {
    package { 'bind-chroot': ensure => 'absent' }
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
