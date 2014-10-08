# puppet_master

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with puppet_master](#setup)
    * [What puppet_master affects](#what-puppet_master-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with puppet_master](#beginning-with-puppet_master)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This Module is to manage a Multi Master environment with a single MOM (all-in-one or split installations)
and multiple compile masters.

## Module Description

The MOM, in an all-in-one installation will contain the CA, PuppetDB, Console, Postgresql, ActiveMQ Hub.
In a split environment the MOM will contain the CA and ActiveMQ Hub.
The MOM is the compile master for ALL Puppet infrastructure.

The Compile masters contain the Puppet cataolg compile service and an ActiveMQ Spoke.

The Compile masters redirect all certificate traffic to the MOM.

Agents do not communicate with the MOM ever!  Agents only commnicate with the Compile masters.

The Compile masters are designed to be behind a load balancer with a common VIP.  The MOM server(s) (all-in-one or split)
are designed to be protected behind firewalls with very limited access (no access from agents).

The module will manage the environment after inital installation of the MOM server(s) and Compile masters.


## Setup

### What puppet_master affects

On MOM
* auth.conf
* PuppetDB certificate whitelist entries for MOM and Compile masters
* Console certificate whitelist entries for MOM and Compile masters

On Compile masters
* ActiveMQ certs & keys
* ActiveMQ Java Keystore files
* puppetmaster.conf certificate redirection

On MOM and Compile masters
* Host entries
* hiera.yaml
* r10k for Hiera and Puppet modules (if desired)
* Environment directories
* Agent's server
* pe-httpd server
* puppetmaster.conf

### Beginning with puppet_master

The files/hiera.yaml should be modified as required

Install a PE 3.3.x Puppet Master as per normal.
Install r10k if desired and configure.
To configure the master as a MOM the following can be performed:

```puppet
    class { 'puppet_master::mom':
      dns_alt_names   => ['ca','ca.puppetlabs.local','puppet','puppet.puppetlabs.local'],
      hiera_backends  => ['yaml'],
      hiera_base      => '/etc/puppetlabs/puppet/hieradata',
      hiera_hierarchy => ['%{clientcert}','global'],
      hiera_remote    => 'https://github.com/glarizza/hiera.git',
      hiera_template  => '/tc/puppetlabs/puppet/hiera.yaml',
      puppet_base     => '/etc/puppetlabs/puppet/environments',
      puppet_remote   => 'https://github.com/glarizza/puppet.git',
      purge_hosts     => false,
      r10k_enabled    => true,
      vip             => 'puppet.puppetlabs.local',
    }
```
For the PuppetDB instance (the MOM in an all-in-one) perform:

```puppet
  class { 'puppet_master::puppetdb':
     default_whitelist => [$::fqdn, 'pe-internal-dashboard'],
     all_in_one        => true,
  }
```
For the Console instance (the MOM in an all-in-one) perform:
```puppet
  class { puppet_master::console:
     default_whitelist => [$::fqdn, 'pe-internal-dashbaord'],
     all_in_one        => true,
  }
```

For Compile masters, the MOM must exist first.
Create an answers file with:
* The MOM is the server for the Compile master.
* The settings for PuppetDB and Console pointing at the correct node (MOM if all-in-one)
Install Puppet as normal. On completion delete the ActiveMQ broker.ts and broker.ks files.
To make the Compile master function perform the following:

```puppet
  class { 'puppet_master::compile':
     ca_enabled      => false,
     ca_server       => 'ca.puppetlabs.local'
     dns_alt_names   => ['com1','com1.puppetlabs.local','puppet','puppet.puppetlabs.local'],
     hiera_backends  => ['yaml'],
     hiera_base      => '/etc/puppetlabs/puppet/hieradata',
     hiera_hierarchy => ['%{clientcert}','global'],
     hiera_remote    => 'https://github.com/glarizza/hiera.git',
     hiera_template  => 'puppet_master/hiera.yaml.erb',
     master          => 'ca.puppetlabs.local',
     puppet_base     => '/etc/puppetlabs/puppet/environments',
     puppet_remote   => 'https://github.com/glarizza/puppet.git',
     purge_hosts     => false,
     r10k_enabled    => true,
     vip             => 'puppet.puppetlabs.local',
  }
```
and
```puppet
  class { 'puppet_master::activemq':
    keystore_passwd => 'g@ry_w3@ars_fl0ppy_sh03s',
    export_keys     => true,
  }
```

## Usage

## Reference

###Classes
* `puppet_master::compile`: manages PE Compile master resources.
* `puppet_master::mom`: manages PE MOM resources.
* `puppet_master::activemq`: manages PE ActiveMQ resources on Compile masters (non-MOM).
* `puppet_master::console`: manages PE Console resources.
* `puppet_master::puppetdb`: manages PE PuppetDB resources.

###Parameters

####puppet_master::compile

#####`ca_enabled`
Boolean value to determine if the node has the CA service enabled.
Default is false,

#####`ca_server`
Host name (string) of the CA if the current node is not.
Default to undef
Required if ca_enabled is false.

#####`dns_alt_names`
Array of DNS Alt Names used for the server alias within the puppetmaster.conf for pe-httpd
Defaults to [ $::hostname, $::fqdn, 'puppet', "puppet.${::domain}"]

#####`hiera_backends`
Array of backends to include in the hiera.yaml file.
Default is ['yaml'].

#####`hiera_base`
Hiera data directory on node.
Default is "${::settings::confdir}/hieradata".

#####`hiera_file`
Location of source for Hiera config file.
Defaults to 'puppet:///modules/puppet_master/hiera.yaml'.

#####`hiera_hierarchy`
Hierarchy to be included in the hiera.yaml file
Default is ['%{clientcert}','global'].

#####`hiera_remote`
URL of the remote GIT repo for Hiera.
Required if ca_enabled is false.

#####`master`
Name of the Puppet master this node will use as its server.  Should be the Master of Masters.
Default os $::fqdn
Required.

#####`puppet_base`
Directory for the Puppet environments.
Targeted towards directory environments.
Default is "${::settings::confdir}/environments".

#####`puppet_remote`
URL of remote GIT repo for Puppetfile.
Default is undef.

#####`purge_hosts`
Boolean value to determine if hosts file is purged of non-Puppet managed entries.
Default is false.

#####`r10k_enabled`
Boolean value to determine if r10k is managed by Puppet.
Default is true.

#####`vip`
VIP name that will be used in the site.pp for the filebucket location.
Defaults to puppet.${::domain}
Required.

```puppet
  class { 'puppet_master::compile':
     ca_enabled      => false,
     ca_server       => 'ca.puppetlabs.local'
     dns_alt_names   => ['com1','com1.puppetlabs.local','puppet','puppet.puppetlabs.local'],
     hiera_backends  => ['yaml'],
     hiera_base      => '/etc/puppetlabs/puppet/hieradata',
     hiera_hierarchy => ['%{clientcert}','global'],
     hiera_remote    => 'https://github.com/glarizza/hiera.git',
     hiera_template  => 'puppet_master/hiera.yaml.erb',
     master          => 'ca.puppetlabs.local',
     puppet_base     => '/etc/puppetlabs/puppet/environments',
     puppet_remote   => 'https://github.com/glarizza/puppet.git',
     purge_hosts     => false,
     r10k_enabled    => true,
     vip             => 'puppet.puppetlabs.local',
  }
```

####puppet_master::mom

#####`dns_alt_names`
Array of DNS Alt Names used for the server alias within the puppetmaster.conf fir pe-httpd
Defaults to [ $::hostname, $::fqdn, 'puppet', "puppet.${::domain}"]
Required.

#####`hiera_backends`
Array of backends to include in the hiera.yaml file.
Default is ['yaml'].

#####`hiera_base`
Hiera data directory on node.
Default is "${::settings::confdir}/hieradata".

#####`hiera_file`
Location of source for Hiera config file.
Defaults to 'puppet:///modules/puppet_master/hiera.yaml'.

#####`hiera_hierarchy`
Hierarchy to be included in the hiera.yaml file
Default is ['%{clientcert}','global'].

#####`hiera_remote`
URL of the remote GIT repo for Hiera.
Required if ca_enabled is false.

#####`puppet_base`
Directory for the Puppet environments.
Targeted towards directory environments.
Default is "${::settings::confdir}/environments".

#####`puppet_remote`
URL of remote GIT repo for Puppetfile.
Default is undef.

#####`purge_hosts`
Boolean value to determine if hosts file is purged of non-Puppet managed entries.
Default is false.

#####`r10k_enabled`
Boolean value to determine if r10k is managed by Puppet.
Default is true.

#####`vip`
VIP name that will be used in the site.pp for the filebucket location.
Defaults to puppet.${::domain}
Required.

```puppet
    class { 'puppet_master::mom':
      dns_alt_names   => ['ca','ca.puppetlabs.local','puppet','puppet.puppetlabs.local'],
      hiera_backends  => ['yaml'],
      hiera_base      => '/etc/puppetlabs/puppet/hieradata',
      hiera_hierarchy => ['%{clientcert}','global'],
      hiera_remote    => 'https://github.com/glarizza/hiera.git',
      hiera_template  => '/tc/puppetlabs/puppet/hiera.yaml',
      puppet_base     => '/etc/puppetlabs/puppet/environments',
      puppet_remote   => 'https://github.com/glarizza/puppet.git',
      purge_hosts     => false,
      r10k_enabled    => true,
      vip             => 'puppet.puppetlabs.local',
    }
```

####puppet_master::activemq

######`keystore_passwd`
Password for Java Keystore.
No default!

######`export_keys`
Boolean value to determine if the exported ActiveMQ keys are imported.
Default is in puppet_master::params
Default is true.

```puppet
  class { 'puppet_master::activemq':
    keystore_passwd => 'g@ry_w3@ars_fl0ppy_sh03s',
    export_keys     => true,
  }
```

####puppet_master::console

#####`default_whitelist`
An array of the default entries in the whitelist
Default is [::fqdn, 'pe-internal-dashbaord']

#####`all_in_one`
Boolean value to determine if the node is an all-in-one installation or split
Default is true.

```puppet
  class { 'puppet_master::console':
     default_whitelist => [$::fqdn, 'pe-internal-dashbaord'],
     all_in_one        => true,
  }
```

####puppet_master::puppetdb

#####`all_in_one`
Boolean value to determine if the node is an all-in-one installation or split
Default is true.

#####`default_whitelist`
An array of the default entries in the whitelist
Default is [::fqdn, 'pe-internal-dashbaord']

```puppet
  class { 'puppet_master::puppetdb':
     default_whitelist => [$::fqdn, 'pe-internal-dashboard'],
     all_in_one        => true,
  }
```

###Defines
* `puppet_master::console::whitelist_entry`: define type for PE Console certificate whitelist entry
* `puppet_master::puppetdb::whitelist_entry`: define type for PE PuppetDB certificate whitelist entry

####puppet_master::console::whitelist_entry

#####`role`
Role (permission) of the node. Can be 'read-write' or 'read-only'
Default is 'read-write'.

#####`order`
Number of where to place the entry in the list
Default is '10'.

```puppet
  puppet_master::console::whitelist_entry { 'com1.puppetlabs.local':
     role  => [$::fqdn, 'pe-internal-dashbaord'],
     order => '20',
  }
```

####puppet_master::puppetdb::whitelist_entry

```puppet
  puppet_master::puppetdb::whitelist_entry { 'com1.puppetlabs.local': }
```

## Limitations

Tested on Centos6.5

## Development

PRs welcome

