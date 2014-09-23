class UserLevel
  include MongoMapper::Document
  key :point, Integer
  key :name, String
  many :users, :foreign_key => :user_id, :class_name => "User"
  one :previous_user_level, :foreign_key => :previous_user_level_id, :class_name => "UserLevel"
  one :next_user_level, :foreign_key => :next_user_level_id, :class_name => "UserLevel"
  def self.get_user_level(point)

  end
end