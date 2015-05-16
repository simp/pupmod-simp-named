require 'spec_helper'

describe 'named::caching::hints' do
  # Look in hieradata/default.yaml for variables that have been set for this test.

  it { should create_class('named::caching::hints') }
  it { should create_file('/var/named/chroot/var/named/named.ca').with_content(/test_content/) }
end
