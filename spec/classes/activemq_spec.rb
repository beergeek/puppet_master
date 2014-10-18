require 'spec_helper'
describe 'puppet_master::activemq' do

  context 'RHEL6 with default parameters' do
    let(:node) { 'com1.puppetlabs.vm' }
    let(:pre_condition) { 'class {"pe_mcollective::activemq": }' }
    let(:facts) {
      {
        :osfamily   => 'RedHat',
        :clientcert => 'com1.puppetlabs.vm'
      }
    }
    let(:params) {
      {
        :keystore_passwd => 'testing',
      }
    }

    it {
      should contain_file('/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-mcollective-servers.pem').with(
        'ensure'  => 'file',
        'owner'   => 'pe-puppet',
        'group'   => 'pe-puppet',
        'mode'    => '0644',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/puppet/ssl/private_keys/pe-internal-mcollective-servers.pem').with(
        'ensure'  => 'file',
        'owner'   => 'pe-puppet',
        'group'   => 'pe-puppet',
        'mode'    => '0640',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/puppet/ssl/certs/pe-internal-mcollective-servers.pem').with(
        'ensure'  => 'file',
        'owner'   => 'pe-puppet',
        'group'   => 'pe-puppet',
        'mode'    => '0644',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-peadmin-mcollective-client.pem').with(
        'ensure'  => 'file',
        'owner'   => 'pe-puppet',
        'group'   => 'pe-puppet',
        'mode'    => '0644',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/puppet/ssl/public_keys/pe-internal-puppet-console-mcollective-client.pem').with(
        'ensure'  => 'file',
        'owner'   => 'pe-puppet',
        'group'   => 'pe-puppet',
        'mode'    => '0644',
      )
    }

    it {
      should contain_java_ks('activemq:truststore').with(
        'ensure'        => 'latest',
        'path'          => [ '/opt/puppet/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
        'certificate'   => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
        'target'        => '/etc/puppetlabs/activemq/broker.ts',
        'password'      => 'testing',
        'trustcacerts'  => true,
      ).that_comes_before('File[/etc/puppetlabs/activemq/broker.ts]')
      .that_notifies('Service[pe-activemq]')
    }

    it {
      should contain_java_ks('activemq:keystore').with(
        'ensure'        => 'latest',
        'path'          => [ '/opt/puppet/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
        'certificate'   => '/etc/puppetlabs/puppet/ssl/certs/com1.puppetlabs.vm.pem',
        'target'        => '/etc/puppetlabs/activemq/broker.ks',
        'password'      => 'testing',
      ).that_comes_before('File[/etc/puppetlabs/activemq/broker.ks]')
      .that_notifies('Service[pe-activemq]')
    }

    it {
      should contain_file('/etc/puppetlabs/activemq/broker.ts').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'pe-activemq',
        'mode'    => '0640',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/activemq/broker.ks').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'pe-activemq',
        'mode'    => '0640',
      )
    }
  end
end
