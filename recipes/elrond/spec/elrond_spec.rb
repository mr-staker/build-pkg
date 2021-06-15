# frozen_string_literal: true

require 'yaml'
require 'fileutils'

require_relative '../lib'
require_relative 'spec_helper'

describe 'elrond' do
  before(:all) do
    FileUtils.rm_f 'validatorKey.pem'
  end

  describe package("elrond-#{build_config[:network]}") do
    it { should be_installed }
  end

  describe command('/opt/elrond/bin/node -v') do
    its(:stdout) { should match /Elrond Node CLI App/ }
    its(:exit_status) { should eq 0 }
  end

  describe command('/opt/elrond/bin/keygenerator') do
    its(:stdout) { should match /generating files in/ }
    its(:exit_status) { should eq 0 }
  end

  describe file('validatorKey.pem') do
    it { should exist }
     its(:content) { should match /-----BEGIN PRIVATE KEY for / }
     its(:content) { should match /-----END PRIVATE KEY for / }
  end

  describe file('/usr/bin/elrond-assessment') do
    it { should be_file }
    it { should be_mode '755' }
  end

  after(:all) do
    FileUtils.rm_f 'validatorKey.pem'
  end
end
