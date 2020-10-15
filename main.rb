require 'dotenv'
Dotenv.load

require 'forwardable'
require 'pry'
require 'tdlib-ruby'
require 'colorize'

# https://github.com/southbridgeio/tdlib-ruby/issues/36
require_relative './lib/tdlib/types'

require_relative './config'
require_relative './lib/td_connection_manager'

TD::Api.set_log_verbosity_level(1)

begin
  TdConnectionManager.connect
rescue SystemExit, Interrupt
  puts "\n\n Exiting..."
end
