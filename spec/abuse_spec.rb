require_relative './init'
require_relative '../event_handlers/three_strikes_and_you_are_out'
require_relative '../event_handlers/create_abuse_report'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
describe "Helper" do
  before do
    IntegrationSpecHelper.InitializeMongo()
    EventBus.subscribe(:abuse_report_filed, CreateAbuseReport.new, :abuse_report_filed)
    EventBus.subscribe(:abuse_report_filed, ThreeStrikesAndYouAreOut.new, :abuse_report_filed)
  end
  before(:each) do
    Token.destroy_all
    Request.destroy_all
    User.destroy_all
  end

  def create_request helper, blind
    request = Request.new
    request.session_id = "session_id"
    request.token = "token"
    request.answered = true
    request.stopped = true
    request.helper = helper
    request.blind = blind
    request.save!
    request
  end

  def create_abuse_report(blind, helper)
   reason = 'we are testing'
   reporter = 'blind'
   request = create_request helper, blind
   EventBus.announce(:abuse_report_filed, request: request, reporter: reporter, reason:reason)
  end

  it "will block user after three reports" do
    helper = build(:helper)
    helper.save

    token = Token.new
    token.user = helper
    token.valid_time = 365.days
    token.save!

    blind = build(:blind)
    blind.save

    create_abuse_report blind, helper
    create_abuse_report blind, helper
    create_abuse_report blind, helper

    expect(helper.blocked).to eq(true)
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

    create_abuse_report blind, helper

    new_request = create_request helper, blind
    new_request.blind = blind
    new_request.save!

    helpers = helper.available new_request, 2000
    expect(helpers).to_not include(helper)
  end
end
