require_relative './rest_shared_context'

describe "Request" do
  include_context "rest-context"

  before(:each) do
    User.destroy_all
    Token.destroy_all
    Blind.destroy_all
    Request.destroy_all
  end

  it "can create a request" do
    register_device
    create_user 'blind'
    token = log_user_in

    create_request_url  = "#{@servername_with_credentials}/requests"
    response = RestClient.post create_request_url, {'token'=> token}.to_json

    expect(response.code).to eq(200)
    jsn = JSON.parse(response.to_s)
    expect(jsn["id"]).to_not eq(nil)
  end

  it "create request and find it waiting" do
    register_device
    create_user 'blind'
    token = log_user_in

    create_request_url  = "#{@servername_with_credentials}/requests"
    RestClient.post create_request_url, {'token'=> token}.to_json

    wr = WaitingRequests.new
    requests = wr.get_waiting_requests_from_lasts_2_minutes
    expect(requests.count).to eq(1)
  end
end
