require_relative '../../chat'

module Menu::Chats
  class Base < Menu::Base
    CHOICES = {
      'b' => 'Go back',
      'r' => 'Refresh'
    }

    def initialize(**)
      super
      @chats = []
      @selected_chats = []
    end

    def show
      puts "\n\n"
      build_chats_list.then do
        print_options
        handle_choice
      end.rescue(&ErrorHandler.handle).wait
    end

    private

    def build_chats_list
      Concurrent::Promises.future do
        chat_list = TD::Types::ChatList::Main.new
        chat_order = 2**63 - 1
        offset_chat_id = 0
        limit = 1000

        client.get_chats(chat_list, chat_order, offset_chat_id, limit).then do |td_chats|
          puts ' Building chats list...'
          td_chats.chat_ids.each do |td_chat_id|
            client.get_chat(td_chat_id).then do |td_chat|
              next unless valid_chat?(td_chat)

              @chats << Chat.new(td_chat, client, @options).tap(&:count_messages)
            end.rescue(&ErrorHandler.handle).wait
          end
        end.rescue(&ErrorHandler.handle).wait
      end
    end

    def valid_chat?(td_chat)
      !td_chat.type.respond_to?(:is_channel) || !td_chat.type.is_channel
    end

    def print_options
      puts ''
      puts "\n Clear messages in one or more available chats (own/unread)"
      puts " Multiple chats can be selected by separating numbers with \",\""
      puts ' ------------------------------------------------------------------'
      @chats.each_with_index do |chat, idx|
        puts " #{idx + 1}: #{chat.option_text}"
      end
      puts "\n or"
      puts ' ------------------------------------------------------------------'
      CHOICES.each do |value, label|
        puts " #{value}: #{label}"
      end
      puts ''
    end

    def handle_choice
      print ' Provide your choice: '
      choice = STDIN.gets.strip

      if choice == 'b'
        go_back
      elsif choice == 'r'
        restart
      elsif chat_ids?(choice)
        @selected_chats = @chats.values_at *chat_ids(choice)
        ask_for_confirmation
      else
        handle_choice
      end
    end

    def go_back
      Menu::Main.new(client: client, options: options).show
    end

    def chat_ids(choices)
      choices.split(',').map(&:strip).map(&:to_i).map { |id| id - 1 }
    end

    def chat_ids?(choices)
      choices.split(',').map(&:strip).all? do |choice|
        chat_id?(choice)
      end
    end

    def chat_id?(choice)
      choice.match?(/\A\d+\z/) && (1..@chats.size).include?(choice.to_i)
    end

    def ask_for_confirmation
      print_confirmation
      choice = STDIN.gets.strip
      if choice == 'Y'
        process_selected_chats
      end
      restart
    end

    def print_confirmation
      puts " Going to:"
      @selected_chats.each do |chat|
        puts "   - delete #{chat.own_count} messages in #{chat.title}"
      end
      print " Are you sure? [Yn]: "
    end

    def process_selected_chats
      @selected_chats.each do |chat|
        chat.search_messages.then do
          chat.delete_messages.then do
            puts " Messages were successfully deleted in #{chat.title}."
          end.rescue(&ErrorHandler.handle).wait
        end.rescue(&ErrorHandler.handle).wait
      end
    end

    def restart
      @chats = []
      @selected_chats = []
      show
    end
  end
end
