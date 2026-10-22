require 'spec_helper'

shared_examples_for 'iptables' do
  it { is_expected.to create_iptables__listen__tcp_stateful('named_dns') }
  it { is_expected.to create_iptables__listen__udp('named_dns') }
end

shared_examples_for 'common install' do
  it { is_expected.to create_group('named') }
  it { is_expected.to create_user('named') }
  it { is_expected.to contain_package('bind').with_ensure('installed') }
  it { is_expected.to contain_package('bind-libs').with_ensure('installed') }
end

shared_examples_for 'named directories' do |working_dir|
  it {
    is_expected.to create_file(working_dir).with(
      ensure: 'directory', owner: 'root', group: 'named', mode: '0770',
    ).that_requires('Rsync[named]')
  }
  ['data', 'slaves'].each do |dir|
    it {
      is_expected.to create_file("#{working_dir}/#{dir}").with(
        ensure: 'directory', owner: 'named', group: 'named', mode: '0770',
      ).that_requires('Rsync[named]')
    }
  end
end

shared_examples_for 'common el7 service' do
  it {
    is_expected.to contain_file('/etc/systemd/system/named-chroot.service').with(
      ensure: 'file',
      owner: 'root',
      group: 'root',
      mode: '0644',
      content: %r{.*ExecStartPre=/bin/bash -c 'if \[ ! "\$DISABLE_ZONE_CHECKING" == "yes" \]; then /usr/sbin/named-checkconf -t /var/named/chroot -z /etc/named.conf; else echo "Checking of zone files is disabled"; fi'.*}, # rubocop:disable Layout/LineLength
    )
  }
  it { is_expected.to contain_exec('named-systemctl-daemon-reload') }
end

describe 'named' do
  def mock_selinux_disabled_facts(os_facts)
    os_facts[:selinux] = false
    os_facts[:os][:selinux][:config_mode] = 'disabled'
    os_facts[:os][:selinux][:current_mode] = 'disabled'
    os_facts[:os][:selinux][:enabled] = false
    os_facts[:os][:selinux][:enforced] = false
    os_facts
  end

  def mock_selinux_enforcing_facts(os_facts)
    os_facts[:selinux] = true
    os_facts[:os][:selinux][:config_mode] = 'enforcing'
    os_facts[:os][:selinux][:config_policy] = 'targeted'
    os_facts[:os][:selinux][:current_mode] = 'enforcing'
    os_facts[:os][:selinux][:enabled] = true
    os_facts[:os][:selinux][:enforced] = true
    os_facts
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:environment) { 'rp_env' }

        context 'with chroot, selinux_enforced => false, firewall => true' do
          let(:params) { { firewall: true } }
          let(:facts) do
            custom = os_facts.dup
            custom = mock_selinux_disabled_facts(custom)
            custom
          end

          # init
          it { is_expected.to create_class('named') }
          it { is_expected.to contain_class('named::chroot') }
          it { is_expected.to contain_class('named::service') }
          it { is_expected.to contain_class('named::install') }
          it_behaves_like('iptables')
          # named::chroot
          it { is_expected.to contain_class('rsync') }
          it { is_expected.to create_file('/var/named/chroot').with_ensure('directory') }
          it { is_expected.to create_file('/var/named/chroot/etc').with_ensure('directory') }
          it { is_expected.to create_file('/var/named/chroot/var').with_ensure('directory') }
          it { is_expected.to create_file('/var/named/chroot/etc/named.conf').with_ensure('file') }
          it_behaves_like('named directories', '/var/named/chroot/var/named')
          it { is_expected.to create_file('/etc/named.conf').with_ensure('/var/named/chroot/etc/named.conf') }
          it {
            is_expected.to contain_rsync('named').with(
              source: "bind_dns_default_#{environment}_#{facts[:os][:name]}_#{facts[:os][:release][:major]}/named/*",
            )
          }
          # named::install
          it_behaves_like('common install')
          it { is_expected.to contain_package('bind-chroot').with_ensure('installed') }
          it { is_expected.to create_file('/var/named').with(ensure: 'directory', owner: 'root', group: 'named', mode: '0770') }
          # named::service
          if ['RedHat', 'CentOS', 'OracleLinux'].include?(os_facts[:os][:name]) && (os_facts[:os][:release][:major].to_i < 7)
            it {
              is_expected.to contain_service('named').with(
                ensure: 'running',
              )
            }
          else
            it {
              is_expected.to contain_service('named-chroot').with(
                ensure: 'running',
              )
            }
            it_behaves_like('common el7 service')
          end

          context 'with sebool_named_write_master_zone set' do
            let(:params) do
              {
                firewall: true,
                sebool_named_write_master_zones: true,
              }
            end

            it { is_expected.not_to contain_selboolean('named_write_master_zones') }
          end
        end

        context 'with non-chroot' do
          let(:facts) do
            custom = os_facts.dup
            custom = mock_selinux_enforcing_facts(custom)
            custom
          end

          # init.pp
          it { is_expected.to create_class('named::non_chroot') }
          it { is_expected.to create_class('named::service').with(chroot: false) }
          it { is_expected.to create_class('named::install').with(chroot: false) }
          # named::non_chroot
          it { is_expected.to create_file('/etc/named.conf').with_ensure('file') }
          it_behaves_like('named directories', '/var/named')
          it {
            is_expected.to contain_rsync('named').with(
              source: "bind_dns_default_#{environment}_#{facts[:os][:name]}_#{facts[:os][:release][:major]}/named/var/named",
            )
          }
          it {
            is_expected.to contain_rsync('named_etc').with(
              source: "bind_dns_default_#{environment}_#{facts[:os][:name]}_#{facts[:os][:release][:major]}/named/etc/*",
            )
          }
          # named::install
          it_behaves_like('common install')
          it { is_expected.to contain_package('bind-chroot').with_ensure('absent') }

          # named::service
          if ['RedHat', 'CentOS', 'OracleLinux'].include?(os_facts[:os][:name]) && (os_facts[:os][:release][:major].to_i >= 7)
            it_behaves_like('common el7 service')
          end
          it {
            is_expected.to contain_service('named').with(
              ensure: 'running',
            )
          }

          context 'with sebool_named_write_master_zone set' do
            let(:params) do
              {
                firewall: true,
                sebool_named_write_master_zones: true,
              }
            end

            it { is_expected.to contain_selboolean('named_write_master_zones').with_value('on') }
          end
        end

        context 'with directory ownership and permissions overridden' do
          let(:params) do
            {
              working_dir_owner: 'named',
              working_dir_group: 'root',
              working_dir_mode: '0750',
              data_dir_owner: 'root',
              data_dir_mode: '0750',
              slaves_dir_group: 'root',
              slaves_dir_mode: '0700',
            }
          end

          [true, false].each do |chroot|
            context "with chroot => #{chroot}" do
              let(:params) { super().merge(chroot: chroot) }
              let(:working_dir) { chroot ? '/var/named/chroot/var/named' : '/var/named' }

              it { is_expected.to create_file(working_dir).with(owner: 'named', group: 'root', mode: '0750') }
              it { is_expected.to create_file("#{working_dir}/data").with(owner: 'root', group: 'named', mode: '0750') }
              it { is_expected.to create_file("#{working_dir}/slaves").with(owner: 'named', group: 'root', mode: '0700') }
            end
          end
        end

        context 'when trying to include ::named::caching' do
          let(:pre_condition) { 'include ::named::caching' }

          # We should get a resource conflict here.
          it { expect { is_expected.to compile.with_all_deps }.to raise_error(%r{cannot include both}) }
        end
      end
    end
  end
end
