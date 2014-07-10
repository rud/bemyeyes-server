require_relative './init'
require 'timecop'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe User do
  before do
    IntegrationSpecHelper.InitializeMongo()
  end

  before(:each) do
    User.destroy_all
    @sut = build(:helper)
    @sut.save
  end

  describe "can create user, with firstname" do
    it {  expect(@sut.first_name).to eq("Helper") }
  end

  describe "awake times in different timezones" do
    it "sets default wake up time in utc" do
      expected = DEFAULT_WAKE_UP_HOUR - 2 #withdraw the utc_offset
      expect(@sut.wake_up_in_seconds_since_midnight).to eq(expected  * 3600)
    end

    it "can change the timezone" do
      @sut.utc_offset = 7
      @sut.wake_up = "07:00"
      @sut.save!

      expect(@sut.wake_up_in_seconds_since_midnight).to eq(0)
    end

    it "can change the wake up time" do
      @sut.wake_up = "10:00"
      @sut.save!

      expect(@sut.wake_up_in_seconds_since_midnight).to eq(8 * 3600)
    end
  end

  describe "only returns awake users" do
    before(:each) do
      Helper.destroy_all
    end
    it "does not wake up asleep helper in DK when blind from US needs help" do
      request = build(:request)

      Timecop.freeze(Time.gm(2014,"jul",9,4,30) ) do
        asleep_users = User.asleep_users.where(:role => "helper")
        expect(asleep_users.count).to eq(1)

        available_helpers = request.helper.available request
        expect(available_helpers.count).to eq(0)
      end
    end

    it "asleep user not returned as awake" do
      @sut.utc_offset = 0
      @sut.go_to_sleep = "22:00"
      @sut.save!
      Timecop.travel(Time.gm(2000,"jan",1,23,15,1) ) do
        awake_users = User.asleep_users
        expect(awake_users.count).to eq(1)
      end
    end

    it "one awake one asleep, only awake is choosen" do
      @sut.utc_offset = 0
      @sut.go_to_sleep = "22:00"
      @sut.save!

      awake = build(:helper)
      awake.utc_offset = 0
      awake.go_to_sleep = "23:30"
      awake.save!

      Timecop.travel(Time.gm(2000,"jan",1,23,15,1) ) do
        asleep_users = User.asleep_users
        expect(asleep_users.count).to eq(1)
      end
    end

    it "user in another timezone, called in the afternoon" do
      @sut.utc_offset = -4
      @sut.go_to_sleep = "22:00"
      @sut.save!
      Timecop.travel(Time.gm(2000,"jan",1,20,15,1) ) do
        asleep_users = User.asleep_users
        expect(asleep_users.count).to eq(0)
      end
    end

    it "user in another timezone, not called in the night" do
      @sut.utc_offset =  4
      @sut.go_to_sleep = "22:00"
      @sut.save!
      Timecop.travel(Time.gm(2000,"jan",1,20,15,1) ) do
        asleep_users = User.asleep_users
        expect(asleep_users.count).to eq(1)
      end
    end

    it "awake user returned as awake" do
      @sut.utc_offset = 0
      @sut.go_to_sleep = "22:00"
      @sut.save!
      Timecop.travel(Time.gm(2000,"jan",1,20,15,1) ) do
        asleep_users = User.asleep_users
        expect(asleep_users.count).to eq(0)
      end
    end
  end
end
