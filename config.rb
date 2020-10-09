TD.configure do |config|
  config.lib_path = File.expand_path('lib/libtdjson', __dir__)

  config.client.api_id = ENV['TG_API_ID']
  config.client.api_hash = ENV['TG_API_HASH']
  config.client.system_version = '28'
end
