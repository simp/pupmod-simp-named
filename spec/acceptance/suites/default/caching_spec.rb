require 'spec_helper_acceptance'

test_name 'named::caching'

describe 'named::caching' do
  let(:manifest) {
    <<-EOS
      include 'named::caching'

      named::caching::forwarders { '8.8.8.8': }
    EOS
  }

  hosts.each do |host|
    # Need this for the 'host' command
    host.install_package('bind-utils')

    context 'with internet connection' do
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be able to lookup www.google.com from itself' do
        on(host, 'echo -e "nameserver 127.0.0.1\nsearch `facter domain`" > /etc/resolv.conf') 
        on(host, 'host www.google.com')
      end
    end
  end
end
