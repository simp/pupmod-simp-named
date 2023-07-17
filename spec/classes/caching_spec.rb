require 'spec_helper'

describe 'named::caching' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do

        context 'with chroot' do
          let(:facts){
            facts = facts.dup
            facts[:os][:selinux][:enforced] = false
            facts
          }

          it { is_expected.to create_file_line('bind_chroot') }
          it { is_expected.to create_file('/etc/named.conf').with(:target => '/var/named/chroot/etc/named.conf')}
          it { is_expected.to create_class('named::install').with(:chroot => true)}
          it { is_expected.to create_class('named::service').with(:chroot => true)}
          it { is_expected.to create_concat('named_caching').with(:path => '/var/named/chroot/etc/named_caching.forwarders')}
          it { is_expected.to create_concat_fragment('named_caching+header')}
          it { is_expected.to create_concat_fragment('named_caching+footer')}
          it { is_expected.to create_file('/var/named/chroot/etc/named.rfc1912.zones')}
          it { is_expected.to create_file('/var/named/chroot/var/named/data')}
          it { is_expected.to create_file('/var/named/chroot/var/named/localdomain.zone')}
          it { is_expected.to create_file('/var/named/chroot/var/named/localhost.zone')}
          it { is_expected.to create_file('/var/named/chroot/var/named/named.broadcast')}
          it { is_expected.to create_file('/var/named/chroot/var/named/named.ip6.local')}
          it { is_expected.to create_file('/var/named/chroot/var/named/named.local')}
          it { is_expected.to create_file('/var/named/chroot/var/named/named.zero')}
          it { is_expected.to create_file('/var/named/chroot/etc/named.conf')}
        end

        context 'with non_chroot' do
          let(:facts){
            facts = facts.dup
            facts[:os][:selinux][:enforced] = true
            facts
          }

          it { is_expected.to_not create_file_line('bind_chroot') }
          it { is_expected.to_not create_file('/etc/named.conf').with(:target => '/var/named/chroot/etc/named.conf')}
          it { is_expected.to create_concat('named_caching').with(:path => '/etc/named_caching.forwarders')}
          it { is_expected.to create_class('named::install').with(:chroot => false)}
          it { is_expected.to create_class('named::service').with(:chroot => false)}
          it { is_expected.to create_concat_fragment('named_caching+header')}
          it { is_expected.to create_concat_fragment('named_caching+footer')}
          it { is_expected.to create_file('/etc/named.rfc1912.zones')}
          it { is_expected.to create_file('/var/named/data')}
          it { is_expected.to create_file('/var/named/localdomain.zone')}
          it { is_expected.to create_file('/var/named/localhost.zone')}
          it { is_expected.to create_file('/var/named/named.broadcast')}
          it { is_expected.to create_file('/var/named/named.ip6.local')}
          it { is_expected.to create_file('/var/named/named.local')}
          it { is_expected.to create_file('/var/named/named.zero')}
          it { is_expected.to create_file('/etc/named.conf')}
        end

        context 'when trying to include ::named' do
          let(:facts) {facts}
          let(:pre_condition){ 'include named'}

          # We should get a resource conflict here.
          it { expect { is_expected.to compile.with_all_deps }.to raise_error(/cannot include both/) }
        end
      end
    end
  end
end
