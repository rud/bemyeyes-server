require_relative './init'
require_relative '../helpers/notifications/iphone_notifier'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe NotificationHandler do
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
    Device.destroy_all
  end

  it "filters out development devices" do
    device = build(:device)
    device.development = true
    device.save!

    devices = Array.new
    devices << device

    request = build(:request)
    request.save!
  end

  it "filters out inactive devices" do
    device = build(:device)
    device.inactive = true
    device.save!

    devices = Array.new
    devices << device

    request = build(:request)
    request.save!

    successor_double = double('successor')
    #should not be called since the only device existing is inactive
    expect(successor_double).to_not receive(:handle_notifications) do |devices, request|
    end

    logger_double = setup_logger
    hash = Hash.new
    sut = IphoneProductionNotifier.new hash, logger_double
    sut.set_successor successor_double
    sut.handle_notifications devices, request
  end
end
