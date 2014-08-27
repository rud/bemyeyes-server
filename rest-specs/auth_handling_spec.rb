require_relative './rest_shared_context'

describe "auth" do
  include_context "rest-context"
  it "can start a reset password flow" do
    register_device
    id = create_user
    user = User.first(:_id => id)

    url = "#{@servername_with_credentials}/auth/request-reset-password"
    RestClient.post url, {:email => user.email}.to_json
  end

  it "cannot start a reset password flow for external user" do
    register_device
    id = create_user
    user = User.first(:_id => id)
    user.is_external_user = true
    user.save!

    url = "#{@servername_with_credentials}/auth/request-reset-password"

    expect{RestClient.post url, {:email => user.email}.to_json}
    .to raise_error(RestClient::BadRequest)
  end
end
