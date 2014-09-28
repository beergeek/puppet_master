# == Defined Type: puppet_master::console::whitelist_entry
#
# Entry for the Console whitelist
#
# === Parameters
#
# [*role*]
#   Role (permission) of the node. Can be 'read-write' or 'read-only'
#   Default is 'read-write'.
#
# [*order*]
#   Number of where to place the entry in the list
#   Default is '10'.
#
# === Examples
#
#  puppet_master::console::whitelist_entry { 'cbr1uberucom1.uberu.local':
#     role  => [$::fqdn, 'pe-internal-dashbaord'],
#     order => '20',
#  }
#
# === Authors
#
# Brett Gray <brett.gray@puppetlabs.vm>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
define puppet_master::console::whitelist_entry (
  $role  = 'read-write',
  $order = '10',
) {

  if ! member(['read-write','read-only'], $role) {
    fail("\$role can only be 'read-write' or 'read-only', not ${role}")
  }

  concat::fragment { $name:
    target  => '/etc/puppetlabs/console-auth/certificate_authorization.yml',
    content => template('puppet_master/console_whitelist.erb'),
    order   => $order,
  } 

}
