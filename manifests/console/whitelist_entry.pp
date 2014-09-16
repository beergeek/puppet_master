define puppet_master::console::whitelist_entry (
  $role  = 'read-write',
  $order = 10,
) {

  if ! match(['read-write','read-only'], $role) {
    fail("\$role can only be 'read-write' or 'read-only', not ${role}")
  }

  concat::fragment { $name:
    target  => '/etc/puppetlabs/console-auth/certificate_authorization.yml',
    content => '---',
    order   => $order,
  } 

}
