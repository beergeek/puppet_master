require 'spec_helper'
describe 'puppet_master::httpd' do

  context 'RHEL6 with default parameters' do

    it {
      should contain_file('/etc/puppetlabs/httpd').with(
        'ensure'  => 'directory',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/httpd/conf.d').with(
        'ensure'  => 'directory',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      )
    }

    it {
      should contain_file('/etc/puppetlabs/httpd/conf.d/puppetmaster.conf').with(
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      ).with_content(/ProxyPassMatch/)
      .that_notifies('Service[pe-httpd]')
    }

    it {
      should contain_service('pe-httpd').with(
        'ensure'  => 'running',
        'enable'  => true,
      )
    }
  end
end
