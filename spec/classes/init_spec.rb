require 'spec_helper'

shared_examples_for "iptables" do
  it { is_expected.to create_iptables__listen__tcp_stateful('named_dns')}
  it { is_expected.to create_iptables__listen__udp('named_dns')}
end

shared_examples_for "common install" do
  it { is_expected.to create_group('named')}
  it { is_expected.to create_user('named') }
  it { is_expected.to contain_package('bind').with_ensure('installed') }
  it { is_expected.to contain_package('bind-libs').with_ensure('installed') }
end

shared_examples_for "common el7 service" do
          it { is_expected.to contain_file('/etc/systemd/system/named-chroot.service').with({
            :ensure  => 'file',
            :owner   => 'root',
            :group   => 'root',
            :mode    => '0644',
            :content => /.*ExecStartPre=\/bin\/bash -c 'if \[ ! "\$DISABLE_ZONE_CHECKING" == "yes" \]; then \/usr\/sbin\/named-checkconf -t \/var\/named\/chroot -z \/etc\/named.conf; else echo "Checking of zone files is disabled"; fi'.*/
          })}
          it { is_expected.to contain_exec('named-systemctl-daemon-reload')}
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
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts){ facts }

        context "with chroot, selinux_enforced => false, firewall => true" do
          let(:params) {{:firewall => true}}
          let(:facts) do
            os_facts = facts.dup
            os_facts = mock_selinux_disabled_facts(os_facts)
            os_facts
          end

          # init
          it { is_expected.to create_class('named') }
          it { is_expected.to contain_class('named::chroot') }
          it { is_expected.to contain_class('named::service')}
          it { is_expected.to contain_class('named::install')}
          it_should_behave_like('iptables')
          # named::chroot
          it { is_expected.to contain_class('rsync')}
          it { is_expected.to create_file('/var/named/chroot').with_ensure('directory') }
          it { is_expected.to create_file('/var/named/chroot/etc').with_ensure('directory') }
          it { is_expected.to create_file('/var/named/chroot/var').with_ensure('directory') }
          it { is_expected.to create_file('/var/named/chroot/etc/named.conf').with_ensure('file') }
          it { is_expected.to create_file('/var/named/chroot/var/named').with_ensure('directory') }
          it { is_expected.to create_file('/etc/named.conf').with_ensure('/var/named/chroot/etc/named.conf') }
          it { is_expected.to contain_rsync('named').with({
            :source => "bind_dns_default_#{environment}_#{facts[:os][:name]}_#{facts[:os][:release][:major].to_s}/named/*"
            })
          }
          # named::install
          it_should_behave_like('common install')
          it { is_expected.to contain_package('bind-chroot').with_ensure('installed')}
          # named::service
          if ['RedHat','CentOS','OracleLinux'].include?(facts[:os][:name]) && (facts[:os][:release][:major].to_s < '7')
            it { is_expected.to contain_service('named').with({
              :ensure => 'running'
            })}
          else
            it {
              is_expected.to contain_service('named-chroot').with({
              :ensure => 'running'
            })}
            it_should_behave_like('common el7 service')
          end

          context 'with sebool_named_write_master_zone set' do
            let(:params) {{
              :firewall                        => true,
              :sebool_named_write_master_zones => true
            }}

            it { is_expected.not_to contain_selboolean('named_write_master_zones') }
          end
        end

        context "with non-chroot" do
          let(:facts) do
            os_facts = facts.dup
            os_facts = mock_selinux_enforcing_facts(os_facts)
            os_facts
          end

          # init.pp
          it { is_expected.to create_class('named::non_chroot') }
          it { is_expected.to create_class('named::service').with(:chroot => false)}
          it { is_expected.to create_class('named::install').with(:chroot => false)}
          # named::non_chroot
          it { is_expected.to create_file('/etc/named.conf').with_ensure('file')}
          it { is_expected.to create_file('/var/named').with_ensure('directory') }
          it { is_expected.to contain_rsync('named').with({
            :source => "bind_dns_default_#{environment}_#{facts[:os][:name]}_#{facts[:os][:release][:major].to_s}/named/var/named"
            })
          }
          it { is_expected.to contain_rsync('named_etc').with({
            :source => "bind_dns_default_#{environment}_#{facts[:os][:name]}_#{facts[:os][:release][:major].to_s}/named/etc/*"
            })
          }
          # named::install
          it_should_behave_like('common install')
          it { is_expected.to contain_package('bind-chroot').with_ensure('absent') }

          # named::service
          if ['RedHat','CentOS','OracleLinux'].include?(facts[:os][:name]) && (facts[:os][:release][:major].to_s >= '7')
            it_should_behave_like('common el7 service')
          end
          it { is_expected.to contain_service('named').with({
            :ensure => 'running'
          })}

          context 'with sebool_named_write_master_zone set' do
            let(:params) {{
              :firewall                        => true,
              :sebool_named_write_master_zones => true
            }}

            it { is_expected.to contain_selboolean('named_write_master_zones').with_value('on') }
          end
        end

        context 'when trying to include ::named::caching' do
          let(:pre_condition){ 'include ::named::caching' }

          # We should get a resource conflict here.
          it { expect { is_expected.to compile.with_all_deps}.to raise_error(/cannot include both/) }
        end
      end
    end
  end
end
