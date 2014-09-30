require 'rspec/core/rake_task'
require './app.rb'
require './lib/mongomodel.rb'
require './lib/create_user_levels.rb'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :create_yuml_output do
  Uml.create_yuml_output
end

task :create_user_levels do
  CreateUserLevels.create_levels
end


task :add_signup_points_to_all_helpers do
  Helper.find_each() do |helper|
    puts helper
    signup_found = false
    helper.helper_points.each() do |hp| 
      if(hp.message == "signup")
        signup_found = true
      end
      puts hp.message
      puts signup_found
    end
    
    if(!signup_found)
      helper_point = HelperPoint. signup()  
      helper.helper_points.push helper_point
      helper.save
    end
  end
end