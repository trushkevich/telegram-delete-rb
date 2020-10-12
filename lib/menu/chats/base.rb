module Menu::Chats
  class Base < Menu::Base
    CHOICES = {
      'b' => 'Go back'
    }

    def initialize(**)
      super
      @chats = []
      @current_chat = nil
      @messages = []
    end

    def show
      puts "\n\n"
      build_chats_list.then do
        print_options
        handle_choice
      end.rescue(&handle_error).wait
    end

    private

    def build_chats_list
      Concurrent::Promises.future do
        chat_list = TD::Types::ChatList::Main.new
        chat_order = 2**63 - 1
        offset_chat_id = 0
        limit = 1000

        client.get_chats(chat_list, chat_order, offset_chat_id, limit).then do |chats|
          chats.chat_ids.each do |chat_id|
            client.get_chat(chat_id).then do |chat|
              next unless valid_chat?(chat)

              @chats << chat
            end.rescue(&handle_error).wait
          end
        end.rescue(&handle_error).wait
      end
    end

    def valid_chat?(chat)
      !chat.type.respond_to?(:is_channel) || !chat.type.is_channel
    end

    def print_options
      puts ''
      puts "\n Clear messages in one of available chats"
      puts ' -----------------------------------------'
      @chats.each_with_index do |chat, idx|
        puts " #{idx + 1}: #{chat.title}"
      end
      puts "\n or"
      puts ' -----------------------------------------'
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
      elsif chat_id?(choice)
        @current_chat = @chats[choice.to_i - 1]
        ask_for_confirmation
      else
        handle_choice
      end
    end

    def go_back
      Menu::Main.new(client: client, options: options).show
    end

    def chat_id?(choice)
      choice.match?(/\A\d+\z/) && (1..@chats.size).include?(choice.to_i)
    end

    def ask_for_confirmation
      search_messages.then do
        print " Going to delete #{@messages.size} messages in \"#{@current_chat.title}\"." \
              " Are you sure? [Yn]: "
        choice = STDIN.gets.strip
        if choice == 'Y'
          delete_messages.then do
            puts " Messages were successfully deleted."
          end.rescue(&handle_error).wait
        end
        restart
      end.rescue(&handle_error).wait
    end

    def search_messages(next_message_id = 0)
      query = ''
      sender_user_id = @options['my_id']
      from_message_id = next_message_id
      offset = 0
      limit = 100
      filter = TD::Types::SearchMessagesFilter::Empty.new
      client.search_chat_messages(
        @current_chat.id, query, sender_user_id, from_message_id,  offset,  limit, filter
      ).then do |result|
        @messages |= result.messages
        if @messages.size < result.total_count
          search_messages(result.messages.last.id)
        end
      end.rescue(&handle_error).wait
    end

    def delete_messages
      message_ids = @messages.map(&:id)
      revoke = true # delete for all members
      Concurrent::Promises.future do
        message_ids.each_slice(100) do |message_ids|
          client.delete_messages(@current_chat.id, message_ids, revoke)
                .rescue(&handle_error).wait
        end
      end.then do
        @messages = []
      end
    end

    def restart
      clear
      show
    end

    def clear
      @chats = []
      @current_chat = nil
      @messages = []
    end
  end
end
