$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'bundler/setup'
Bundler.setup


module Rails
  def self.env
    :test
  end

  def self.development?
    false
  end

  def self.production?
    false
  end

  def self.test?
    true
  end
end

require 'active_support/all'
require 'active_model'
require 'elasticsearch/model'
require 'elasticsearch/persistence'
require 'active_elastic'
