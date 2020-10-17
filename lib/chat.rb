class Chat
  extend Forwardable

  attr_reader :td_chat, :options, :own_count

  def_delegators :@td_chat, :id,
                            :title,
                            :unread_count,
                            :can_be_deleted_only_for_self,
                            :can_be_deleted_for_all_users

  def initialize(td_chat, client, options = {})
    @td_chat = td_chat
    @client = client
    @options = options
    @own_count = 0
    @messages = []
  end

  def count_messages
    query = ''
    sender_user_id = @options['my_id']
    from_message_id = 0
    offset = 0
    # e.g. messages with content type TD::Types::MessageContent::ChatAddMembers can't be deleted
    # nor for self nor for all, but they appear only on joining chat, so there should not be many
    # of them and limit=100 should be sufficient to find all such messages and exclude from count
    limit = 100
    filter = TD::Types::SearchMessagesFilter::Empty.new
    @client.search_chat_messages(
      td_chat.id, query, sender_user_id, from_message_id,  offset,  limit, filter
    ).then do |result|
      undeletable_messages_count = result.messages.select do |message|
        !message.can_be_deleted_only_for_self && !message.can_be_deleted_for_all_users
      end.size
      @own_count = result.total_count - undeletable_messages_count
    end.rescue(&ErrorHandler.handle).wait.wait
  end

  def option_text
    own = own_count > 0 ? own_count.to_s.red : 0
    unread = unread_count > 0 ? unread_count.to_s.red : 0

    "#{title} (#{own}/#{unread})"
  end

  def option_modifiers
    modifers = ''
    modifers << 'h' if can_be_deleted_only_for_self
    modifers << 'H' if can_be_deleted_for_all_users
    modifers.ljust(2, ' ')
  end

  def search_messages(next_message_id = 0)
    query = ''
    sender_user_id = @options['my_id']
    from_message_id = next_message_id
    offset = 0
    limit = 100
    filter = TD::Types::SearchMessagesFilter::Empty.new
    @client.search_chat_messages(
      id, query, sender_user_id, from_message_id,  offset,  limit, filter
    ).then do |result|
      @messages |= result.messages
      if @messages.size < result.total_count
        search_messages(result.messages.last.id)
      end
    end.rescue(&ErrorHandler.handle).wait
  end

  def delete_messages
    message_ids_for_all = @messages.select(&:can_be_deleted_for_all_users).map(&:id)
    message_ids_for_self = @messages.select(&:can_be_deleted_only_for_self).map(&:id)
    Concurrent::Promises.future do
      message_ids_for_all.each_slice(100) do |message_ids|
        @client.delete_messages(id, message_ids, true)
              .rescue(&ErrorHandler.handle).wait
      end
      message_ids_for_self.each_slice(100) do |message_ids|
        @client.delete_messages(id, message_ids, false)
              .rescue(&ErrorHandler.handle).wait
      end
    end.then do
      @messages = []
    end.wait
  end

  def delete_chat_history(for_all: false)
    remove_from_chat_list = false
    # delete chat history for all members (if possible)
    revoke = for_all && can_be_deleted_for_all_users
    @client.delete_chat_history(id, remove_from_chat_list, revoke)
           .rescue(&ErrorHandler.handle).wait
  end
end
