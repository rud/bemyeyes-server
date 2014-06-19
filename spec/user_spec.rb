require_relative './init'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe Blind do

  before do
    IntegrationSpecHelper.InitializeMongo()
    @sut = build(:blind)
    
    @sut.save
  end

 describe "can create user" do
    it {  expect(@sut.first_name).to eq("Blind") }
  end
end
