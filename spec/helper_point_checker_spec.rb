require 'mongo_mapper'
require 'factory_girl'

require_relative './factories'
require_relative '../helpers/helper_point_checker'
require_relative '../models/helper_request'
require_relative '../models/request'
require_relative '../models/helper_points'
require_relative '../models/helper'
require_relative './integration_spec_helper'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
describe HelperPointChecker do  
  before do
    IntegrationSpecHelper.InitializeMongo()
    @sut = HelperPointChecker.new
  end

  before(:each) do
      HelperPoint.destroy_all
      HelperRequest.destroy_all
    end
  it "No helper requests does nothing" do
      @sut.check_helper_points
      
      count = HelperPoint.count() 
      expect(count).to be(0)
  end
  it "one helper request exists for helper with high five - no points" do 
     helper = build(:helper) 
     helper.save
     create_high_five_for_helper(helper)
     

    @sut.check_helper_points
      
    count = HelperPoint.count() 
    expect(count).to be(0)
  end

  it "five high fives in one week - 10 points" do 
     helper = build(:helper) 
     helper.save

     5.times do 
        create_high_five_for_helper(helper)
     end

    @sut.check_helper_points
      
    count = HelperPoint.all(:user_id => helper.id).count
    expect(count).to eq(1)
  end
  def create_high_five_for_helper(helper)
    request = Request.new
     helper_request = HelperRequest.new
     helper_request.helper = helper
     helper_request.save
     request.helper_request << helper_request 
     request.save
  end

end 