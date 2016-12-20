# This define determines what to add to the /var/named/named.ca root hints file.
#
# @param content
#   Can be set to arbitrary content of your choosing. This will be included
#   verbatim in the named.ca file.
#
# @param use_defaults
#   Set to true if you wish to use the default values for the root hints
#   file. This is recommended if you are not running within an intranet.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class named::caching::hints (
  String  $content      = '',
  Boolean $use_defaults = false
) {

  file { '/var/named/chroot/var/named/named.ca':
    ensure  => 'file',
    owner   => 'root',
    group   => 'named',
    mode    => '0640',
    content => template('named/named.ca.erb'),
    notify  => Class['named::service']
  }
}
