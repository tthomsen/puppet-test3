require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'
master_fqdn = "test.beacker.vm"
master = only_host_with_role(hosts, 'master')

hosts.each do |host|
  if host['roles'].include?('master')
    on master, "yum -y install puppet-server"
    on master, "echo '*' > /etc/puppet/autosign.conf"
    on master, "mkdir -p /etc/puppet/hiera"

    config = {
      'main' => {
        'server'   => master_fqdn,
        'certname' => master_fqdn,
        'logdir'   => '/var/log/puppet',
        'vardir'   => '/var/lib/puppet',
        'ssldir'   => '/var/lib/puppet/ssl',
        'rundir'   => '/var/run/puppet'
      },
      'agent' => {
        'certname' => master_fqdn,
        'classfile'   => '$vardir/classes.txt',
        'localconfig' => '$vardir/localconfig',
        'environment' => 'production',
        'pluginsync'  => 'true',
        'masterport'  => '8140'
      },
      'master' => {
        'pluginsync' => 'true'
      }
    }

    configure_puppet_on(master, config)
  end
end

RSpec.configure do |c|
  puts "RSpec configure"
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    puts "RSpec configure before"
    # Install module and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'test')
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
