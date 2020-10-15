class Chat
  extend Forwardable

  attr_reader :td_chat, :options, :own_count

  def_delegators :@td_chat, :id, :title, :unread_count

  def initialize(td_chat, client, options = {})
    @td_chat = td_chat
    @client = client
    @options = options
    @own_count = 0
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
end
