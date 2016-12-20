# This define adds forwarders entries to your caching nameserver configuration
# file.
#
# $name can be a whitespace delimited list of values to provide backward
# compatibility with the common::resolv format.
#
# @example
#   named::caching::forwarders { '1.2.3.4': ensure => 'present' }
#   named::caching::forwarders { '1.2.3.4 5.6.7.8 9.10.11.12':
#     ensure => 'present'
#   }
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
define named::caching::forwarders {

  $_name = inline_template('<%= @name.delete(";").split.join("_") %>')

  simpcat_fragment { "named_caching+${_name}.forward":
    content =>
      inline_template('<%= (@name.delete(";").split - ["127.0.0.1", "::1"]).join(";\n") + ";" %>')
  }
}
