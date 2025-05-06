require 'spec_helper'

describe 'named::caching::hints' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) { facts }

        it { is_expected.to create_class('named::caching::hints') }
        it { is_expected.to create_file('/var/named/chroot/var/named/named.ca').with_content(%r{test_content}) }
      end
    end
  end
end
