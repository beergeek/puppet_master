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
      hiera_base    => '/etc/puppetlabs/puppet/hieradata',
      hiera_remote  => 'https://github.com/glarizza/hiera.git',
      puppet_base   => '/etc/puppetlabs/puppet/environments',
      puppet_remote => 'https://github.com/glarizza/puppet.git',
      purge_hosts   => false,
      r10k_enabled  => true,
      vip           => 'puppet.puppetlabs.local',
      dns_alt_names => ['ca','ca.puppetlabs.local','puppet','puppet.puppetlabs.local'],
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

## Usage

Put the classes, types, and resources for customizing, configuring, and doing
the fancy stuff with your module here.

## Reference

Here, list the classes, types, providers, facts, etc contained in your module.
This section should include all of the under-the-hood workings of your module so
people know what the module is touching on their system but don't need to mess
with things. (We are working on automating this section!)

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.

## Release Notes/Contributors/Etc **Optional**

If you aren't using changelog, put your release notes here (though you should
consider using changelog). You may also add any additional sections you feel are
necessary or important to include here. Please use the `## ` header.
