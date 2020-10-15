class Chat
  extend Forwardable

  attr_reader :td_chat, :options, :own_count

  def_delegators :@td_chat, :id, :title, :unread_count

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
    limit = 1
    filter = TD::Types::SearchMessagesFilter::Empty.new
    @client.search_chat_messages(
      td_chat.id, query, sender_user_id, from_message_id,  offset,  limit, filter
    ).then do |result|
      @own_count = result.total_count
    end.rescue(&ErrorHandler.handle).wait.wait
  end

  def option_text
    own = own_count > 0 ? own_count.to_s.red : 0
    unread = unread_count > 0 ? unread_count.to_s.red : 0

    "#{title} (#{own}/#{unread})"
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
    message_ids = @messages.map(&:id)
    revoke = true # delete for all members
    Concurrent::Promises.future do
      message_ids.each_slice(100) do |message_ids|
        @client.delete_messages(id, message_ids, revoke)
              .rescue(&ErrorHandler.handle).wait
      end
    end.then do
      @messages = []
    end.wait
  end
end
