require 'mongomapper_id2'

class Token
  include MongoMapper::Document

  key :token, String, :unique => true
  key :expiry_date, Date
  belongs_to :user
  
  before_create :generate_token
  before_create :calculate_expiry_date
  
  def to_json()
    return { "token" => self.token }.to_json
  end
  
  def valid()
    return Time.now < self.expiry_date
  end
  
  private
  def generate_token()
    self.token = SecureRandom.urlsafe_base64(64, false)
  end
  
  private
  def calculate_expiry_date()
    now = Time.now
    self.expiry_date = Time.new(now.year, now.month, now.day, 0, 0, 0) + 3.days
  end
end