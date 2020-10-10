class GroupsMenu
  def initialize
    @current_user = nil
    @groups = []
    @current_group = nil
    @messages = []
  end

  def show
    load_current_user.then do
      build_groups_list.then do
        select_and_confirm_group
      end.rescue(&handle_error).wait
    end.rescue(&handle_error).wait
  end

  private

  def load_current_user
    $client.get_me.then do |user|
      @current_user = user
    end.rescue(&handle_error).wait
  end

  def build_groups_list
    Concurrent::Promises.future do
      puts "\n\n"

      chat_list = TD::Types::ChatList::Main.new
      chat_order = 2**63 - 1
      offset_chat_id = 0
      limit = 1000

      groups = []

      $client.get_chats(chat_list, chat_order, offset_chat_id, limit).then do |chats|
        chats.chat_ids.each do |chat_id|
          $client.get_chat(chat_id).then do |chat|
            next if chat.type.is_a?(TD::Types::ChatType::Private) ||
                    chat.type.respond_to?(:is_channel) && chat.type.is_channel

            @groups << chat
          end.rescue(&handle_error).wait
        end
      end.rescue(&handle_error).wait
    end
  end

  def show_groups_list
    puts "\n AVAILABLE GROUPS"
    puts ' ----------------'
    @groups.each_with_index do |group, idx|
      puts " #{idx + 1}. #{group.title}"
    end
    puts ''
  end

  def select_group
    loop do
      print " Enter a number of a group where messages should be deleted: "
      number = STDIN.gets.strip

      break if @current_group = @groups[number.to_i - 1]
    end
  end

  def select_and_confirm_group
    clear_messages
    show_groups_list
    select_group
    ask_for_confirmation
  end

  def ask_for_confirmation
    search_messages.then do
      print " Going to delete #{@messages.size} messages in \"#{@current_group.title}\"." \
            " Are you sure? [Yn]: "
      choice = STDIN.gets.strip
      if choice == 'Y'
        delete_messages.then do
          puts " Messages were successfully deleted.\n\n"
        end.rescue(&handle_error).wait
      end
      select_and_confirm_group
    end.rescue(&handle_error).wait
  end

  def search_messages(next_message_id = 0)
    query = ''
    sender_user_id = @current_user.id
    from_message_id = next_message_id
    offset = 0
    limit = 100
    filter = TD::Types::SearchMessagesFilter::Empty.new
    $client.search_chat_messages(
      @current_group.id, query, sender_user_id, from_message_id,  offset,  limit, filter
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
        $client.delete_messages(@current_group.id, message_ids, revoke).then do
          clear_messages
        end.rescue(&handle_error).wait
      end
    end
  end

  def clear_messages
    @messages = []
  end

  def handle_error
    Proc.new do |err|
      puts " error: #{err}"
    end
  end
end
