require_relative './rest_shared_context'

describe "Helpers" do
  include_context "rest-context"

  before(:each) do
    User.destroy_all
    Request.destroy_all
    HelperRequest.destroy_all
  end

  it "does not mark a cancelled request as waiting" do
    blind_token = create_blind_ready_to_make_request
    helper_token, helper_id = create_helper_ready_for_call
    request_id = create_request blind_token

    answer_request(request_id, helper_token)
    cancel_request(request_id, helper_token)

    waiting_request_id = get_waiting_request_id helper_id

    expect(waiting_request_id).to eq(0)
  end

  it "returns id of waiting requests" do
    blind_token = create_blind_ready_to_make_request
    helper_token, helper_id = create_helper_ready_for_call

    request_id = create_request(blind_token)

    expect(HelperRequest.count(:helper_id => helper_id)).to eq(1)

    waiting_request_id = get_waiting_request_id helper_id

    expect(waiting_request_id).to eq(request_id)
  end

  def get_waiting_request_id helper_id
    waiting_requests_url  = "#{@servername_with_credentials}/helpers/waiting_request/#{helper_id}"
    response = RestClient.get waiting_requests_url

    expect(response.code).to eq(200)

    jsn = JSON.parse response.body
    id = jsn['id']
    id
  end

  def create_blind_ready_to_make_request
    register_device
    create_user 'blind'
    blind_token = log_user_in
    blind_token
  end

  def create_helper_ready_for_call
    device_token = 'Helper device token'
    device_system_version ='iPhone for test'
    role ="helper"
    email = create_unique_email
    password = encrypt_password 'helperPassword'
    register_device device_token, device_system_version
    user_id = create_user role, email, password
    token = log_user_in email, password, device_token

    return token, user_id
  end

  def answer_request short_id, token
    answer_request_url  = "#{@servername_with_credentials}/requests/#{short_id}/answer"
    response = RestClient.put answer_request_url, {'token'=> token}.to_json
  end

  def cancel_request short_id, token
    cancel_request_url  = "#{@servername_with_credentials}/requests/#{short_id}/answer/cancel"
    response = RestClient.put cancel_request_url, {'token'=> token}.to_json
  end

  def create_request token
    create_request_url  = "#{@servername_with_credentials}/requests"
    response = RestClient.post create_request_url, {'token'=> token}.to_json

    expect(response.code).to eq(200)

    jsn = JSON.parse(response.to_s)
    jsn["id"]
  end
end
