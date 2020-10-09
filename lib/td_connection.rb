require_relative './groups_menu'

class TdConnection
  def self.establish
    new.establish
  end

  def establish
    begin
      state = nil

      $client.on(TD::Types::Update::AuthorizationState) do |update|
        state = case update.authorization_state
                when TD::Types::AuthorizationState::WaitPhoneNumber
                  :wait_phone_number
                when TD::Types::AuthorizationState::WaitCode
                  :wait_code
                when TD::Types::AuthorizationState::WaitPassword
                  :wait_password
                when TD::Types::AuthorizationState::Ready
                  :ready
                else
                  nil
                end
      end

      $client.connect

      loop do
        case state
        when :wait_phone_number
          puts 'Please, enter your phone number:'
          phone = STDIN.gets.strip
          $client.set_authentication_phone_number(phone, nil).wait
        when :wait_code
          puts 'Please, enter code from SMS:'
          code = STDIN.gets.strip
          $client.check_authentication_code(code).wait
        when :wait_password
          puts 'Please, enter 2FA password:'
          password = STDIN.gets.strip
          $client.check_authentication_password(password).wait
        when :ready
          GroupsMenu.new.show
          break
        end
        sleep 0.1
      end
    ensure
      $client.dispose
    end
  end
end
