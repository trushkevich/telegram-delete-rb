require 'pry'
require 'tdlib-ruby'

# https://github.com/southbridgeio/tdlib-ruby/issues/36
require_relative './lib/tdlib/types'

require_relative './config'
require_relative './lib/td_connection'

TD::Api.set_log_verbosity_level(1)

$client = TD::Client.new

TdConnection.establish
