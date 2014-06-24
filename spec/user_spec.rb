require_relative './init'
require 'timecop'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe User do

  before do
    IntegrationSpecHelper.InitializeMongo()
    User.destroy_all
    @sut = build(:blind)
    
    @sut.save
  end

  describe "can create user" do
    it {  expect(@sut.first_name).to eq("Blind") }
  end

  describe "awake times in different timezones" do
   it "sets default wake up time in utc" do
    expect(@sut.wake_up_in_seconds_since_midnight).to eq(DEFAULT_WAKE_UP_HOUR * 3600)
  end   

  it "can change the timezone" do
    @sut.utc_offset = -7
    @sut.save!

    expect(@sut.wake_up_in_seconds_since_midnight).to eq(0)
  end

  it "can change the wake up time" do
    @sut.wake_up = "10:00"
    @sut.save!

    expect(@sut.wake_up_in_seconds_since_midnight).to eq(10 * 3600)
  end
end

describe "only returns awake users" do
  before do
    Timecop.freeze(Time.local(1990))
  end
  it "asleep user not notified" do

  end
end
end
