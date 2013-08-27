require 'mongomapper_id2'

class Request
  include MongoMapper::Document

  key :short_id, String
  key :session_id, String
  key :token, String
  key :name, String
  auto_increment!
  timestamps!

  before_create :create_short_id

  private
  def create_short_id
      self.short_id = RequestIDShortener.new.encrypt(self.id2)
  end
end