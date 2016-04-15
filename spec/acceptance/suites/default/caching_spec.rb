require 'spec_helper_acceptance'

test_name 'named::caching'

describe 'named::caching' do
  let(:manifest) {
    <<-EOS
      include 'named::caching'

      named::caching::forwarders { '8.8.8.8': }
    EOS
  }

  context 'with internet connection' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do

      hosts.each do |host|
        # Need this for the 'host' command
        host.install_package('bind-utils')

        apply_manifest_on(host, manifest, :catch_failures => true)

        on(host, 'host www.google.com')
      end
    end
  end
end
