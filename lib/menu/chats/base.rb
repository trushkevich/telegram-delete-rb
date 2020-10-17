require_relative '../../chat'

module Menu::Chats
  class Base < Menu::Base
    CHOICES = {
      'b' => 'Go back',
      'r' => 'Refresh'
    }

    def init
      @chats = []
      @selected_chats = []
      @delete_own_history_in_chats = []
      @delete_all_history_in_chats = []
    end

    def show
      puts "\n\n"
      init
      build_chats_list.then do
        print_options
        handle_choice
      end.rescue(&ErrorHandler.handle).wait
    end

    alias restart show

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
      puts " Appending \"h\" to chat number (1h) will also delete history for self"
      puts " Appending \"H\" to chat number (1H) will also delete history for all"
      puts ' ---------------------------------------------------------------------'
      @chats.each_with_index do |chat, idx|
        puts " #{idx + 1} [#{chat.option_modifiers}]: #{chat.option_text}"
      end
      puts "\n or"
      puts ' ---------------------------------------------------------------------'
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
        select_chats(choice)
        ask_for_confirmation
      else
        handle_choice
      end
    end

    def go_back
      Menu::Main.new(client: client, options: options).show
    end

    def select_chats(choice)
      @selected_chats = @chats.values_at *chat_ids(choice)
      @delete_own_history_in_chats = @chats.values_at *chat_ids_for_history(choice, for_all: false)
      @delete_all_history_in_chats = @chats.values_at *chat_ids_for_history(choice, for_all: true)
    end

    def chat_ids(signatures)
      signatures.split(',').map(&:strip).map(&:to_i).map { |id| id - 1 }
    end

    def chat_ids_for_history(signatures, for_all:)
      modifier = for_all ? 'H' : 'h'
      signatures.split(',').map(&:strip).select do |signature|
        signature.include?(modifier)
      end.map(&:to_i).map { |id| id - 1 }
    end

    def chat_ids?(signatures)
      signatures.split(',').map(&:strip).all? do |signature|
        chat_id?(signature)
      end
    end

    def chat_id?(signature)
      signature.match?(/\A\d+[hH]?\z/) && (1..@chats.size).include?(signature.to_i)
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
        puts "   - delete #{chat.own_count} messages in \"#{chat.title}\""
      end
      @delete_all_history_in_chats.each do |chat|
        puts "   - clear history for all in \"#{chat.title}\""
      end
      @delete_own_history_in_chats.each do |chat|
        puts "   - clear history only for self in \"#{chat.title}\""
      end
      print " Are you sure? [Yn]: "
    end

    def process_selected_chats
      delete_messages
      delete_own_history
      delete_all_history
    end

    def delete_messages
      @selected_chats.each do |chat|
        chat.search_messages.then do
          chat.delete_messages.then do
            puts " Messages were successfully deleted in \"#{chat.title}\"."
          end.rescue(&ErrorHandler.handle).wait
        end.rescue(&ErrorHandler.handle).wait
      end
    end

    def delete_own_history
      @delete_own_history_in_chats.each do |chat|
        chat.delete_chat_history(for_all: false).then do
          puts " History was successfully cleared only for self in \"#{chat.title}\"."
        end.rescue(&ErrorHandler.handle).wait
      end
    end

    def delete_all_history
      @delete_all_history_in_chats.each do |chat|
        chat.delete_chat_history(for_all: true).then do
          puts " History was successfully cleared for all in \"#{chat.title}\"."
        end.rescue(&ErrorHandler.handle).wait
      end
    end
  end
end
