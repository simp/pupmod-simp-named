require 'spec_helper'

shared_examples_for "iptables" do
  it { is_expected.to create_iptables_rule('allow_dns_tcp')}
  it { is_expected.to create_iptables_rule('allow_dns_udp')}
end

shared_examples_for "common install" do
  it { is_expected.to create_group('named')}
  it { is_expected.to create_user('named').that_requires('Group[named]')}
  it { is_expected.to contain_package('bind').with_ensure('latest') }
  it { is_expected.to contain_package('bind-libs').with_ensure('latest') }
end

shared_examples_for "common el7 service" do
          it { is_expected.to contain_file('/usr/lib/systemd/system/named-chroot.service').with({
            :ensure  => 'file',
            :owner   => 'root',
            :group   => 'root',
            :mode    => '0644',
            :content => /.*ExecStartPre=\/bin\/bash -c 'if \[ ! "\$DISABLE_ZONE_CHECKING" == "yes" \]; then \/usr\/sbin\/named-checkconf -t \/var\/named\/chroot -z \/etc\/named.conf; else echo "Checking of zone files is disabled"; fi'.*/
          })}
          it { is_expected.to contain_exec('systemctl-daemon-reload')}
end

describe 'named' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts){ facts }

        context "with chroot, selinux_enforced => false, firewall => true" do
          let(:params) {{:firewall => true}}
          let(:facts){ facts.merge({ :selinux_enforced => false })}

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
          it { is_expected.to contain_package('bind-chroot').with_ensure('latest')}
          # named::service
          if ['RedHat','CentOS'].include? facts[:os][:name] and facts[:os][:release][:major].to_s < '7' then
            it { is_expected.to contain_service('named').with({
              :ensure => 'running'
            })}
          else
            it { is_expected.to contain_service('named-chroot').with({
              :ensure => 'running'
            })}
            it_should_behave_like('common el7 service')
          end

        end

        context "with non-chroot" do
          let(:facts){ facts.merge({ :selinux_enforced => true })}

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
          if ['RedHat','CentOS'].include? facts[:os][:name] and facts[:os][:release][:major].to_s >= '7' then
            it_should_behave_like('common el7 service')
          end
          it { is_expected.to contain_service('named').with({
            :ensure => 'running'
          })}
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
