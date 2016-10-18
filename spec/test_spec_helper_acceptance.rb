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
      if host['roles'].include?('master')
        puts "copy hiera.yaml"
        scp_to master, File.join(proj_root, 'spec', 'fixtures', 'hiera.yaml'), File.join('/etc', 'puppet', 'hiera.yaml')
        #scp_to master, File.join(proj_root, 'spec', 'fixtures', 'zookeeper.json'), File.join('/etc', 'puppet', 'hiera', 'default.json')
        #scp_to master, File.join(proj_root, 'spec', 'fixtures', 'r10k', 'ZookeeperPuppetfile'), File.join('/etc', 'puppet', 'Puppetfile')

        on master, "gem install r10k"

        cmd = 'PUPPETFILE=/etc/puppet/Puppetfile PUPPETFILE_DIR=/etc/puppet/modules r10k puppetfile install --verbose debug2 --color 2>&1'
        on master, cmd

        on master, "mkdir -p /etc/puppet/modules/test"
        Dir.foreach(proj_root) do |item|
          puts "copy module files"
          next if item == '.' or item == '..' or item == '.git' or item == '.gitignore' or item == 'spec'

          puts item
          scp_to master, File.join(proj_root, item), '/etc/puppet/modules/test'
        end

        on master, "service puppetmaster restart"
      end
    end
  end
end
