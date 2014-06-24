require_relative './init'
require 'timecop'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe User do

  before do
    IntegrationSpecHelper.InitializeMongo()
    User.destroy_all
    @sut = build(:helper)

    @sut.save
  end

  describe "can create user, with firstname" do
    it {  expect(@sut.first_name).to eq("Helper") }
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
    it "asleep user not returned as awake" do
      @sut.utc_offset = 0
      @sut.go_to_sleep = "22:00"
      @sut.save!
      Timecop.travel(Time.gm(2000,"jan",1,23,15,1) ) do
        awake_users = User.awake_users
        expect(awake_users.count).to eq(0)
      end
   
    end

     it "awake user returned as awake" do
      @sut.utc_offset = 0
      @sut.go_to_sleep = "22:00"
      @sut.save!
      Timecop.travel(Time.gm(2000,"jan",1,20,15,1) ) do
        awake_users = User.awake_users
        expect(awake_users.count).to eq(1)
      end
    end
  end
end
