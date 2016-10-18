require 'spec_helper'

describe 'test' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "test class without any parameters" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('test::params') }
          it { is_expected.to contain_class('test::install').that_comes_before('test::config') }
          it { is_expected.to contain_class('test::config') }
          it { is_expected.to contain_class('test::service').that_subscribes_to('test::config') }

          it { is_expected.to contain_service('test') }
          it { is_expected.to contain_package('test').with_ensure('present') }
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'test class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        {
          :osfamily        => 'Solaris',
          :operatingsystem => 'Nexenta',
        }
      end

      it { expect { is_expected.to contain_package('test') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
