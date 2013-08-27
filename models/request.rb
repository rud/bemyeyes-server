require 'mongomapper_id2'

class Request
  include MongoMapper::Document

  key :short_id, String
  key :session_id, String
  key :token, String
  key :blind_name, String
  key :helper_name, String
  key :answered, Boolean
  key :blind_rating, Integer
  key :helper_rating, Integer
  auto_increment!
  timestamps!

  before_create :create_short_id

  private
  def create_short_id
      self.short_id = RequestIDShortener.new.encrypt(self.id2)
  end
end