require 'hashids'

class RequestIDShortener < Hashids
  @@minimum_length = 4

  def initialize(salt)
    super(salt, @@minimum_length)
  end
end