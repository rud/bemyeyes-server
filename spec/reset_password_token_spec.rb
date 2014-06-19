require_relative './init'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
describe "Reset Password Token" do
  before do
    IntegrationSpecHelper.InitializeMongo()
  end
  before(:each) do
    Helper.destroy_all
    ResetPasswordToken.destroy_all
  end

  it "Can create a token" do
    helper = build(:helper)
    helper.save

    token = ResetPasswordToken.create
    token.user = helper
    token.save!
  end
end
