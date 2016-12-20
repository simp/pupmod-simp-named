# Params
#
# @param chroot_path
#   If set, enables the chroot jailed version of named.
#   Simply set to an empty string ("") if you want named outside of a chroot
#   jail with SELinux disabled.
#
#   This is the default if you do not have SELinux enabled.
#   Chroot jails for named are not compatible with SELinux and will be
#   disabled is SELinux is enforcing.
#
class named::params {
  $chroot_path = '/var/named/chroot'
}
