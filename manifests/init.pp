# == Class: named
#
# This class configures named for execution on a system using selinux.
# It pulls all config files from rsync.
#
# You will need to ensure that rsync is serving out the appropriate space so
# that the configuration can be pulled.
#
# The default SIMP configuration will do this for the 'default' space, but
# other spaces will need to be added as appropriate.
#
# @example
#   * Given 'default' configuration that you would like to serve
#   * Create a chroot pull from that domain on your DNS node
#       include 'named'
#
#   * Create the associated hieradata
#       ---
#       named::bind_dns_rsync : 'default'
#       rsync::server : 'rsync.foo.bar'
#
#   * Ensure that the rsync space is being served out properly from the rsync
#     server (probably your puppet master)
#       include 'rsync::server'
#       # The word 'default' here is the equivalent of the
#       # named::bind_dns_rsync variable above.
#       rsync::server::section { "bind_dns_default_${environment}":
#         auth_users  => ['bind_dns_default_rsync'],
#         comment     => 'DNS "default" configuration',
#         path        => "${rsync_base}/bind_dns/default",
#         hosts_allow => 127.0.0.1 # This is correct if using stunnel
#
# @param chroot_path
#   If set, enables the chroot jailed version of named.
#   Simply set to an empty string ("") if you want named outside of a chroot
#   jail with SELinux disabled.
#
#   This is the default if you do not have SELinux enabled.
#   Chroot jails for named are not compatible with SELinux and will be
#   disabled if SELinux is enforcing.
#
#   * Value in module data
#
# @param chroot
#   Toggle the use of chroot and override the autodetected setting to be
#   compatible with SELinux.
#
#   * WARNING: If you have an SELinux enabled system, forcing the chroot may
#     cause named to become non-functional.
#
# @param bind_dns_rsync
#   The target under "${rsync_base}/bind_dns" from which to fetch all
#   BIND DNS content.
#
# @param firewall
#   Enable SIMP firewall management
#
# @param rsync_server
#   The rsync server from which to pull the named configuration.
#
# @param rsync_timeout
#   The timeout when connecting to the rsync server.
#
# @param sebool_named_write_master_zones
#   If you need to use dynamic DNS or zone transfers, and are using SELinux,
#   you will need to set this to ``true``
#
# @author https://github.com/simp/pupmod-simp-named/graphs/contributors
#
class named (
  Stdlib::Absolutepath    $chroot_path,
  Boolean                 $chroot                          = !pick($facts['selinux_enforced'], false),
  String                  $bind_dns_rsync                  = 'default',
  Boolean                 $firewall                        = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  String                  $rsync_server                    = simplib::lookup('simp_options::rsync::server', { 'default_value' => '127.0.0.1' }),
  Stdlib::Compat::Integer $rsync_timeout                   = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => '2' }),
  Boolean                 $sebool_named_write_master_zones = false
) {

  if defined(Class['named::caching']) {
    fail('You cannot include both ::named and ::named::caching')
  }

  simplib::assert_metadata( $module_name )

  simplib::validate_net_list($rsync_server)

  if $chroot {
    include 'named::chroot'
    include 'named::service'
    include 'named::install'

    Class['named::install'] -> Class['named::chroot']
    Class['named::chroot'] -> Class['named::service']
  }
  else {
    include 'named::non_chroot'
    class { 'named::service': chroot => false }
    class { 'named::install': chroot => false }

    Class['named::install'] -> Class['named::non_chroot']
    Class['named::non_chroot'] -> Class['named::service']
  }

  Class['named::install'] ~> Class['named::service']

  if $facts['selinux_enforced'] {
    $_selboolean_value = $sebool_named_write_master_zones ? {true => 'on', default => 'off'}
    selboolean { 'named_write_master_zones':
      persistent => true,
      value      => $_selboolean_value
    }
  }

  if $firewall {
    iptables_rule { 'allow_dns_tcp':
      table   => 'filter',
      order   => '11',
      content => '-m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT'
    }
    iptables_rule { 'allow_dns_udp':
      table   => 'filter',
      order   => '11',
      content => '-p udp --dport 53 -j ACCEPT'
    }
  }
}
