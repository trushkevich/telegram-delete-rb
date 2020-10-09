require_relative './types/poll_type'
require_relative './types/poll'

TD::Types::LOOKUP_TABLE = TD::Types::LOOKUP_TABLE.merge(
  'PollType'        => 'PollType',
  'pollTypeRegular' => 'PollType::Regular',
  'pollTypeQuiz'    => 'PollType::Quiz'
)
