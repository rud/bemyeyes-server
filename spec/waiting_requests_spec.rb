require 'factory_girl'

require_relative './factories'
require_relative '../helpers/waiting_requests'
require_relative '../models/init'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe WaitingRequests do
	before do
	IntegrationSpecHelper.InitializeMongo()
  end
	before(:each) do
		@sut = WaitingRequests.new
		Request.destroy_all
		request = build(:request)
    request.save
	end

	it "sends requests" do
		requests = @sut.get_waiting_requests_from_lasts_2_minutes
		expect(requests.count).to eq(1)
	end
end