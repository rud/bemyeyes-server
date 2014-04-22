require 'rspec/core/rake_task'
require './app.rb'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :add_signup_points_to_all_helpers do
  Helper.find_each() do |helper|
    if(helper.helper_points.count == 0)
      helper_point = HelperPoint. signup()  
      helper.helper_points.push helper_point
      helper.save
    end
  end
end