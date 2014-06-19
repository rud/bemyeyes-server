require_relative './init'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe Request do
before do
	IntegrationSpecHelper.InitializeMongo()
    
    @sut = build(:request)
    @sut.save
  end

 describe "can create Request" do
    it { expect(@sut.answered).to eq(false) }
  end
end
