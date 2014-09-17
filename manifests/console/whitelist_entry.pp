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
