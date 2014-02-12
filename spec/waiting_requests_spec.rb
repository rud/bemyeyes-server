require 'factory_girl'

require_relative './factories'
require_relative '../helpers/waiting_requests'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe WaitingRequests do
	before(:each) do
		@sut = WaitingRequests.new
		Request.destroy_all
		request = build(:request)
    	request.save
	end

	it "sends requests" do
		requests = @sut.get_waiting_requests_from_lasts_2_minutes
		requests.count.should eq(1)
	end
end