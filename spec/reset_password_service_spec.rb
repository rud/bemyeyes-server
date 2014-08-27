require_relative './init'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe "ResetPasswordService" do

  def setup_logger
    log_instance_double = double('logger instance')
    allow(log_instance_double).to receive(:info)
    logger_double = double('logger')
    allow(logger_double).to receive(:log).and_return(log_instance_double)
    logger_double
  end

  before do
    IntegrationSpecHelper.InitializeMongo()
  end
  before(:each) do
    Helper.destroy_all
    ResetPasswordToken.destroy_all
  end

  it "can reset a password" do
    helper = build(:helper)
    helper.save

    old_password = helper.password_hash

    reset_password_token = ResetPasswordToken.new
    reset_password_token.user =  helper
    reset_password_token.save!
    logger_double = setup_logger

    sut = ResetPasswordService.new logger_double

    new_password = 'password1'
    success, message = sut.reset_password reset_password_token.token, new_password
    expect(success).to eq(true)

    helper.reload
    auth_user = User.authenticate_using_email helper.email, new_password

    expect(auth_user).to_not eq(nil)
  end
end
