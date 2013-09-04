require 'mongomapper_id2'

class Request
  include MongoMapper::Document

  belongs_to :blind, :class_name => "Blind"
  belongs_to :helper, :class_name => "Helper"

  key :short_id, String
  key :session_id, String, :required => true
  key :token, String, :required => true
  key :answered, Boolean
  key :blind_rating, Integer
  key :helper_rating, Integer

  auto_increment!
  timestamps!

  before_create :create_short_id
  
  def short_id_salt=(salt)
    @short_id_salt = salt
  end
  
  def to_json()
    return { "opentok" => {
               "session_id" => self.session_id,
               "token" => self.token
             },
             "short_id" => self.short_id,
             "ratings" => {
               "blind" => self.blind_rating,
               "helper" => self.helper_rating
             },
             "answered" => self.answered
           }.to_json
  end

  private
  def create_short_id
    self.short_id = RequestIDShortener.new(@short_id_salt).encrypt(self.id2)
  end
end