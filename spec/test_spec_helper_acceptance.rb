require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'
master_fqdn = "test.beacker.vm"
master = only_host_with_role(hosts, 'master')
puts "output of master"
puts master

puts "hosts"
puts hosts

hosts.each do |host|
  puts "hosts each"
  if host['roles'].include?('master')
    puts "hosts each master"
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
    puts "RSpec configure before hosts"
    puts hosts
    hosts.each do |host|
      puts "RSpec configure before hosts each"
      if host['roles'].include?('master')
        puts "copy hiera.yaml"
        scp_to master, File.join(proj_root, 'spec', 'fixtures', 'hiera', 'hiera.yaml'), File.join('/etc', 'puppet', 'hiera.yaml')
        puts "copy radioevent.json"
        scp_to master, File.join(proj_root, 'spec', 'fixtures', 'hiera', 'radioevent.json'), File.join('/etc', 'puppet', 'hiera', 'default.json')
        puts "copy Puppetfile"
        scp_to master, File.join(proj_root, 'spec', 'fixtures', 'r10k', 'Puppetfile'), File.join('/etc', 'puppet', 'Puppetfile')

        on master, "gem install r10k"

        cmd = 'PUPPETFILE=/etc/puppet/Puppetfile PUPPETFILE_DIR=/etc/puppet/modules r10k puppetfile install --verbose debug2 --color 2>&1'
        on master, cmd

        on master, "mkdir -p /etc/puppet/modules/test"
        puts proj_root
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
