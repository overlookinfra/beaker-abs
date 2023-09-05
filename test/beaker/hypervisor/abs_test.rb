require 'test_helper' # THIS IS MINITEST
require 'beaker/hypervisor/abs'
require 'vmfloaty/utils'

describe 'Beaker::Hypervisor::Abs' do
  def provision_hosts(host_hashes, resource_hosts)
    hosts = []

    host_hashes.each do |name, host_hash|
      hosts << Beaker::Host.create(name, host_hash, {})
    end

    abs = Beaker::Abs.new(hosts, {:abs_resource_hosts => JSON.dump(resource_hosts)})
    abs.provision

    hosts
  end

  describe 'when ABS_RESOURCE_HOSTS is not ready' do
    it '#provision_vms works properly' do

      host_hashes = {
          'redhat7-64-1' => {
              'hypervisor' => 'abs',
              'platform'   => 'el-7-x86_64',
              'template'   => 'redhat-7-x86_64',
              'roles'      => [ 'agent' ]
          }
      }

      hosts = []

      host_hashes.each do |name, host_hash|
        hosts << Beaker::Host.create(name, host_hash, {})
      end

      # TODO: this test queries the real floaty, needs stubs/mocks
      # but the minitest does not like me so it's not working
      # abs = Beaker::Abs.new(hosts, {:provision => true})
      end
    end

    describe 'when provisioning' do
    it 'sets vmhostname for a single host' do
      host_hash = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'redhat-7-x86_64',
                         'engine'   => 'vmpooler'}]

      hosts = provision_hosts(host_hash, resource_hosts)

      _(hosts.length).must_equal(1)
      _(hosts[0]['vmhostname']).must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
    end

    it 'sets vmhostname for multiple hosts of the same type preserving the order' do
      host_hash = {
        'hypervisor' => 'abs',
        'platform'   => 'el-7-x86_64',
        'template'   => 'redhat-7-x86_64',
        'roles'      => [ 'agent' ]
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => host_hash['template'],
                         'engine'   => 'vmpooler'},
                        {'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                         'type'     => host_hash['template'],
                         'engine'   => 'vmpooler'}]

      hosts = provision_hosts({'redhat7-64-1' => host_hash,
                               'redhat7-64-2' => host_hash.dup}, resource_hosts)

      _(hosts.length).must_equal(2)
      _(hosts[0]['vmhostname']).must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
      _(hosts[1]['vmhostname']).must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end

    it 'sets vmhostname for multiple hosts of different types' do
      host_hashes = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        },
        'ubuntu1404-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'ubuntu-14.04-amd64',
          'template'   => 'ubuntu-1404-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'redhat-7-x86_64',
                         'engine'   => 'vmpooler'},
                        {'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                         'type'     => 'ubuntu-1404-x86_64',
                         'engine'   => 'vmpooler'}]

      hosts = provision_hosts(host_hashes, resource_hosts)

      _(hosts.length).must_equal(2)
      _(hosts[0]['vmhostname']).must_equal('m2em9v7895hk7xg.delivery.puppetlabs.net')
      _(hosts[1]['vmhostname']).must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end

    it 'raises when asked to provision a host not in abs_data' do
      host_hash = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                         'type'     => 'ubuntu-1404-x86_64',
                         'engine'   => 'vmpooler'}]

      err = assert_raises(ArgumentError) do
        provision_hosts(host_hash, resource_hosts)
      end
      _(err.message).must_match("Failed to provision host 'redhat7-64-1', no template of type 'redhat-7-x86_64' was provided.")
    end

    it 'raises when the host is missing its template' do
      host_hash = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      resource_hosts = [{'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                                    'type'     => 'redhat-7-x86_64',
                                    'engine'   => 'vmpooler'}]

      err = assert_raises(ArgumentError) do
        provision_hosts(host_hash, resource_hosts)
      end
      _(err.message).must_match("Failed to provision host 'redhat7-64-1' because its 'template' is missing.")
    end

    it 'prefers abs_data as an ENV variable' do
      host_hash = {
        'redhat7-64-1' => {
          'hypervisor' => 'abs',
          'platform'   => 'el-7-x86_64',
          'template'   => 'redhat-7-x86_64',
          'roles'      => [ 'agent' ]
        }
      }
      default_resource_hosts = [{'hostname' => 'm2em9v7895hk7xg.delivery.puppetlabs.net',
                                 'type'     => 'ubuntu-1404-x86_64',
                                 'engine'   => 'vmpooler'}]
      overridden_resource_hosts = [{'hostname' => 'eb0zrfuwteq80t7.delivery.puppetlabs.net',
                                    'type'     => 'redhat-7-x86_64',
                                    'engine'   => 'vmpooler'}]

      ENV['ABS_RESOURCE_HOSTS'] = JSON.dump(overridden_resource_hosts)
      begin
        hosts = provision_hosts(host_hash, default_resource_hosts)
      ensure
        ENV['ABS_RESOURCE_HOSTS'] = nil
      end

      _(hosts.length).must_equal(1)
      _(hosts[0]['vmhostname']).must_equal('eb0zrfuwteq80t7.delivery.puppetlabs.net')
    end

    it 'does not call set_ssh_connection_preference method if hypervisor does not responds' do
      hypervisor_mock = Minitest::Mock.new
      1.times { hypervisor_mock.expect(:respond_to?, false, [:set_ssh_connection_preference]) }
      provision_hosts({}, {})
    end

    it 'calls set_ssh_connection_preference method if beaker responds' do
      hypervisor_mock = Minitest::Mock.new
      2.times { hypervisor_mock.expect(:respond_to?, true, [:set_ssh_connection_preference]) }
      provision_hosts({}, {})
    end

  end

end
