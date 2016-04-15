require 'spec_helper'

describe 'named::caching' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts){ facts }
        it { is_expected.to create_class('named::caching') }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_file('/etc/named.rfc1912.zones') }
        it { is_expected.to contain_service('named').with_ensure('running') }
        context 'with selinux enabled' do
          it { is_expected.to create_file('/etc/named.conf') }
        end
        context 'with selinux disabled' do
          let(:facts) { facts.merge( { :selinux_enforced => false } ) }  
          let(:params) {{ :chroot_path => '/var/named/chroot' }}
          it { is_expected.to contain_package('bind-chroot') }
          it { is_expected.to create_file('/etc/named.conf').with_ensure('symlink') }
          it { is_expected.to create_file('/var/named/chroot/etc/named.conf')  }
        end
      end
    end
  end
end
