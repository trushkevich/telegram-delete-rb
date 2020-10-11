class Menu::Base
  attr_reader :client, :options

  def initialize(client:, options: {})
    @client = client
    @options = options
  end

  private

  def handle_error
    Proc.new do |err|
      puts " error: #{err}"
      puts err.backtrace
    end
  end
end
