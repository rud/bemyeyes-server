require 'mongo_mapper'

require_relative './factories'
require_relative '../models/init'
require_relative './integration_spec_helper'
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
describe "Helper" do
  before do
    IntegrationSpecHelper.InitializeMongo()
  end
  before(:each) do
    Helper.destroy_all
    Token.destroy_all
  end

  def create_request
   request = Request.new
    request.session_id = "session_id"
    request.token = "token"
    request.answered = true
    request.stopped = true
    request.save!
    request
  end

  it "will not let a blind meet a helper from an abusive request" do
    helper = build(:helper)
    helper.save

    token = Token.new
    token.user = helper
    token.valid_time = 365.days
    token.save!

    blind = build(:blind)
    blind.save

    abuse_report = AbuseReport.new
    abuse_report.reason = 'we are testing'
    abuse_report.reporter = 'blind'
    abuse_report.save!

    abusive_request = create_request
    abusive_request.blind = blind
    abusive_request.helper = helper
    abusive_request.abuse_report = abuse_report
    abusive_request.save!

    new_request = create_request
    new_request.blind = blind
    new_request.save!

    helpers = helper.available new_request, 2000
    helpers.should_not include(helper)
  end
end
