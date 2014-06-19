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
end 