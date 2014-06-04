require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'
require_relative '../../app'
require_relative '../../spec/rest-specs/rest_shared_context'
require_relative '../../models/token'
require_relative '../integration_spec_helper'

describe "abuse handling" do
  def create_request(token_repr)
    session_id = 'session_id'
    token = Token.first(:token => token_repr)
    request = Request.create
    request.short_id_salt = 'short_id_salt'
    request.session_id = session_id
    request.token = token
    request.blind = token.user
    request.answered = false
    request.save!
    request
  end
  #include token and helper_request id
  include_context "rest-context"

def report_abuse(token, helper_request_id)
    url = "#{@servername_with_credentials}/abuse/report"
    response = RestClient.post url, 
      {'token' =>token, 'helper_request_id'=>helper_request_id, 'reason'=> 'abusive stuff'}.to_json

    response.code.should eq(200)
end

  before(:each) do
    AbuseReport.destroy_all
  end

  it "will complain if no parameters are sent" do
    url = "#{@servername_with_credentials}/abuse/report"
    expect{ RestClient.post url, {}.to_json}
    .to raise_error(RestClient::BadRequest)
  end

  it "will let blind report abuse" do
    register_device
    create_user
    token = log_user_in

    #we could add a helper and all to the request, but for this test we don't need it
    request = create_request token
    helper_request = HelperRequest.new
    request = request
    helper_request.save!
    report_abuse token, helper_request.id
   AbuseReport.count.should eq(1)
  end
end 
