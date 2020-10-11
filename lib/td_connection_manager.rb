require 'singleton'
require_relative './td_connection'

class TdConnectionManager
  include Singleton

  def self.connect
    instance.connect
  end

  def initialize
    @current_connection = nil
  end

  def connect
    current_connection.connect
  end

  def current_connection
    if @current_connection && !%i[logging_out closed].include?(@current_connection.state)
      @current_connection
    else
      @current_connection = new_connection
    end
  end

  private

  def new_connection
    TdConnection.new
  end
end
