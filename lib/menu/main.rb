class Menu::Main < Menu::Base
  CHOICES = {
    '1' => 'List group chats',
    '2' => 'List private chats',
    '3' => 'Logout'
  }

  def initialize(**)
    super
    @current_user = nil
  end

  def show
    puts "\n\n"
    load_current_user.then do
      print_options
      handle_choice
    end.rescue(&handle_error).wait
  end

  private

  def load_current_user
    client.get_me.then do |user|
      @current_user = user
    end.rescue(&handle_error).wait
  end

  def print_options
    puts " Signed in as: +#{@current_user.phone_number}"
    puts ''
    CHOICES.each do |value, label|
      puts " #{value}: #{label}"
    end
    puts ''
  end

  def handle_choice
    print ' Provide your choice: '
    choice = STDIN.gets.strip

    case choice
    when '1'
      show_group_chats_menu
    when '2'
      show_private_chats_menu
    when '3'
      log_out
    else
      handle_choice
    end
  end

  def show_group_chats_menu
    Menu::Chats::Group.new(client: client, options: @options).show
  end

  def show_private_chats_menu
    Menu::Chats::Private.new(client: client, options: @options).show
  end

  def log_out
    client.log_out.rescue(&handle_error).wait
  end
end
