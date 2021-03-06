class Menu::Chats::Private < Menu::Chats::Base
  private

  def valid_chat?(chat)
    super && chat.type.is_a?(TD::Types::ChatType::Private)
  end
end
