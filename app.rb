require 'bundler'
require 'active_support/core_ext/string'
require 'pry'
require 'guacamole'

ENV['RACK_ENV'] = 'development' unless ENV['RACK_ENV'].present?
Bundler.require(:default, :development)
Dotenv.load ".env.#{ENV['RACK_ENV']}"

Mail.delivery_method.settings = {
  address: ENV['SMTP_ADDRESS'],
  port: ENV['SMTP_PORT'] || 465,
  ssl: ENV['SMTP_USE_SSL'] == '1',
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  domain: ENV['SMTP_DOMAIN']
}

# FIXME: Put this into Guacamole::Collection
module Guacamole::Collection
  included do
    include ClassMethods
  end

  module ClassMethods
    def ensure_hash_index(options={})
      on = Array.wrap options[:on]

      unless connection.indices.detect {|index| index.on == on }
        connection.add_index :hash, on: on, unique: options[:unique]
      end
    end
  end
end

ENV['GUACAMOLE_ENV'] = ENV['RACK_ENV']
Guacamole.configure do |config|
  logger = Logger.new("log/#{ENV['GUACAMOLE_ENV']}.log")
  logger.level = 1
  config.logger = logger

  config_filename = File.join(File.dirname(__FILE__), 'config', 'guacamole.yml')
  File.open('/tmp/guacamole.yml', 'w') { |f| f.write ERB.new(File.read(config_filename)).result }
  config.load '/tmp/guacamole.yml'
end

$:.unshift 'app/models'
require 'user'
require 'users_collection'
require 'repository'
require 'repositories_collection'
