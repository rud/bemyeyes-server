require 'rspec/core/rake_task'
require './app.rb'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :add_signup_points_to_all_helpers do
  Helper.find_each() do |helper|
    signup_found = false
    helper.helper_points.each() do |hp| 
      if(hp.message = "signup")
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