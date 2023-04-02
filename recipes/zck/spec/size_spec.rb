# frozen_string_literal: true

require_relative 'spec_helper'

describe 'size' do
  test_path = ''
  if ENV['IN_DOCKER']
    test_path = '/build/'
  end

  Dir["#{test_path}pkg/*"].each do |pkg|
    describe file(pkg) do
      # this is a hard limit for CF Pages
      its(:size) { should < 26_214_400 }
    end
  end
end
