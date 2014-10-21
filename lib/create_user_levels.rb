require_relative '../models/init.rb'

class CreateUserLevels
  def self.create_levels
    UserLevel.delete_all

    user_level5 = create_level('Master Helper', 5000, nil)
    user_level4 = create_level('Expert Helper', 2000, user_level4)
    user_level3 = create_level('Trusted Helper', 500, user_level4)
    user_level2 = create_level('Promising Helper', 200, user_level3)
    create_level('New Helper', 0, user_level2)

   #calculate level for each user
   Helper.find_each do |helper|
    helper.set_user_level
    helper.save!
   end
  end

  def self.create_level(name, point_threshold, next_user_level)
    user_level = UserLevel.new
    user_level.point_threshold = point_threshold
    user_level.name = name
    user_level.next_user_level = next_user_level unless next_user_level.nil?
    user_level.save!
    user_level
  end
end
