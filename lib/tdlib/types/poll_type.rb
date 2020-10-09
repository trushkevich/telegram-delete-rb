module TD::Types
  # Represents the type of the poll.
  # The following types are possible: regular polls and quiz polls.
  class PollType < Base
    require_relative './poll_type/quiz'
    require_relative './poll_type/regular'
  end
end
