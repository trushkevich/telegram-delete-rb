require_relative './menu'

class TdConnection
  attr_reader :state, :client

  def initialize
    @client = nil
    @state = nil
    @options = {}
  end

  def connect
    @client = TD::Client.new

    subscribe_to_updates

    @client.connect

    main_loop
  ensure
    dispose_client
  end

  private

  def subscribe_to_updates
    subscribe_to_authorization_state
    subscribe_to_option
  end

  def subscribe_to_authorization_state
    @client.on(TD::Types::Update::AuthorizationState) do |update|
      @state = case update.authorization_state
               when TD::Types::AuthorizationState::WaitPhoneNumber
                 :wait_phone_number
               when TD::Types::AuthorizationState::WaitCode
                 :wait_code
               when TD::Types::AuthorizationState::WaitPassword
                 :wait_password
               when TD::Types::AuthorizationState::Ready
                 :ready
               when TD::Types::AuthorizationState::LoggingOut
                 print " Logging out...\r"
                 :logging_out
               when TD::Types::AuthorizationState::Closed
                 puts " Logging out... done\n\n"
                 :closed
               else
                 nil
               end
    end
  end

  def subscribe_to_option
    @client.on(TD::Types::Update::Option) do |update|
      next unless update.name == 'my_id'

      @options[update.name] = update.value.value
    end
  end

  def main_loop
    loop do
      case @state
      when :wait_phone_number then wait_phone_number
      when :wait_code         then wait_code
      when :wait_password     then wait_password
      when :ready
        on_ready
      when :closed
        dispose_client
        TdConnectionManager.connect
        break
      end
      sleep 0.1
    end
  end

  def wait_phone_number
    print ' Please, enter your phone number: '
    phone = STDIN.gets.strip
    @client.set_authentication_phone_number(phone, nil).wait
  end

  def wait_code
    print ' Please, enter code from SMS: '
    code = STDIN.gets.strip
    @client.check_authentication_code(code).wait
  end

  def wait_password
    print ' Please, enter 2FA password: '
    password = STDIN.gets.strip
    @client.check_authentication_password(password).wait
  end

  def on_ready
    Menu::Main.new(client: @client, options: @options).show
  end

  def dispose_client
    @client.dispose
  end
end
