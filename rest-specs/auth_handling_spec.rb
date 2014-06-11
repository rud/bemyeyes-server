require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'
require_relative '../app'
require_relative './rest_shared_context'
require_relative '../models/init'
require_relative '../spec/integration_spec_helper'

describe "auth" do
  include_context "rest-context"

  it "can start a reset password flow" do 
    register_device
    id = create_user
    user = User.first(:_id => id)

    url = "#{@servername_with_credentials}/auth/reset-password"
    p url
     RestClient.post url, {:email => user.email}.to_json
  end
end 