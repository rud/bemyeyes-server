require_relative './init'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe Request do
  before do
    IntegrationSpecHelper.InitializeMongo()
  end

  describe "running requests" do
    before(:each) do
      Request.destroy_all
    end
    def create_request running
      rq1 = build(:request)
      rq1.stopped = !running
      rq1.save!
    end

    it "can find running requests" do
      create_request true
      create_request true
      create_request false

      expect(Request.running_requests().count).to eq(2)
    end
  end
  describe "can create Request" do
    before do
      @sut = build(:request)
      @sut.save
    end
    it { expect(@sut.answered).to eq(false) }
  end
end
