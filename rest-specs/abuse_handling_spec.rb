require_relative './rest_shared_context'

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
  include_context "rest-context"

  def report_abuse(token, request_id)
    url = "#{@servername_with_credentials}/abuse/report"
    response = RestClient.post url,
      {'token' =>token, 'request_id'=>request_id, 'reason'=> 'abusive stuff'}.to_json

    expect(response.code).to eq(200)
  end

  before(:each) do
    User.destroy_all
  end

  it "will complain if no parameters are sent" do
    url = "#{@servername_with_credentials}/abuse/report"
    expect{ RestClient.post url, {}.to_json}
    .to raise_error(RestClient::BadRequest)
  end

  it "will not accept a abuse report if reporter is  not logged in " do
    register_device
    create_user
    token = log_user_in

    #we could add a helper and all to the request, but for this test we don't need it
    request = create_request token

    #log user out
    logoutUser_url  = "#{@servername_with_credentials}/users/logout"
    RestClient.put logoutUser_url, {'token'=> token}.to_json


    expect{report_abuse token, request.id}
    .to raise_error(RestClient::Unauthorized)
  end

  it "will let user report abuse" do
    register_device
    user_id = create_user
    token = log_user_in

    #we could add a helper and all to the request, but for this test we don't need it
    request = create_request token
    report_abuse token, request.id

    user = User.first(:id => user_id)
    expect(user.abuse_reports.count).to eq(1)
  end
end
