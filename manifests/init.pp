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
# Example:
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
#       include 'rsync::server::global'
#       # The word 'default' here is the equivalent of the
#       # named::bind_dns_rsync variable above.
#       rsync::server::section { 'bind_dns_default':
#         auth_users  => ['bind_dns_default_rsync'],
#         comment     => 'DNS "default" configuration',
#         path        => "${rsync_base}/bind_dns/default",
#         hosts_allow => 127.0.0.1 # This is correct if using stunnel
#
# == Parameters
#
# [*chroot_path*]
#   If set, enables the chroot jailed version of named.
#   Simply set to an empty string ("") if you want named outside of a chroot
#   jail with SELinux disabled.
#
#   This is the default if you do not have SELinux enabled.
#   Chroot jails for named are not compatible with SELinux and will be
#   disabled is SELinux is enforcing.
#
# [*bind_dns_rsync*]
#   Type: String
#   Default: default
#     The target under "${rsync_base}/bind_dns" from which to fetch all
#     BIND DNS content.
#
# [*rsync_server*]
#   Type: FQDN
#   Default: hiera(rsync::server)
#     The rsync server from which to pull the named configuration.
#
# [*rsync_timeout*]
#   Type: Integer
#   Default: hiera(rsync::timeout,'2')
#     The timeout when connecting to the rsync server.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
# * Kendall Moore <kmoore@keywcorp.com>
#
class named (
  $chroot_path = $::named::params::chroot_path,
  $bind_dns_rsync = 'default',
  $rsync_server = hiera('rsync::server'),
  $rsync_timeout = hiera('rsync::timeout','2')
) inherits ::named::params {
  include '::rsync'

  if !empty($chroot_path) { validate_absolute_path($chroot_path) }
  validate_string($bind_dns_rsync)
  validate_net_list($rsync_server)
  validate_integer($rsync_timeout)

  if ( str2bool($::selinux_enforced) ) or ( empty($chroot_path) and ! str2bool($::selinux_enforced)) {
    include '::named::non_chroot'
    class { 'named::service': chroot => false }
  }
  else {
    include '::named::chroot'
    include '::named::service'
  }

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

  group { 'named':
    ensure    => 'present',
    allowdupe => false,
    gid       => '25'
  }

  package {
    [ 'bind',
      'bind-libs',
    ]:
    ensure => 'latest'
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

  compliance_map()
}
