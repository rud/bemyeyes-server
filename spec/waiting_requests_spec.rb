require_relative './init'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe WaitingRequests do
  before do
    IntegrationSpecHelper.InitializeMongo()
  end
  before(:each) do
    User.destroy_all
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
