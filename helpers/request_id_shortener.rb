require 'hashids'

class RequestIDShortener < Hashids
  @@salt = 'H5anb5WsRDzvFL3zv5c4AySdYTwkXaUYfaGrw7UTL2W6UBNq'
  @@minimum_length = 4

  def initialize
    super(@@salt, @@minimum_length)
  end
end