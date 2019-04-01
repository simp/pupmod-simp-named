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
# @author https://github.com/simp/pupmod-simp-named/graphs/contributors
#
define named::caching::forwarders {

  include 'named::caching'

  $_name = inline_template('<%= @name.delete(";").split.join("_") %>')

  concat_fragment { "named_caching+${_name}.forward":
    order  => 20,
    target => 'named_caching',
    content =>
      inline_template('<%= (@name.delete(";").split - ["127.0.0.1", "::1"]).join(";\n") + ";" %>')
  }
}
