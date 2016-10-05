# This class installs the appropriate packages for BIND based on the chroot
# status
#
# @private
#
# @param ensure [String] The `package` ensure setting for installed packages
#   @see https://docs.puppet.com/puppet/latest/reference/type.html#package-attribute-ensure
# @param chroot [Boolean] Whether or not to use a chroot jail
# @param chroot_path [Absolute_Path] The path to the chroot jail
class named::install (
  $ensure = 'latest',
  $chroot = false,
  $chroot_path = $::named::chroot_path
){
  assert_private()

  if $::osfamily == 'RedHat' {
    package { 'bind': ensure => $ensure }
    package { 'bind-libs': ensure => $ensure }

    if $chroot {
      package { 'bind-chroot': ensure => $ensure }
    }
    else {
      package { 'bind-chroot': ensure => 'absent' }
    }
  }
  else {
    fail("Operating System ${::operatingsystem} is not yet supported")
  }
}
