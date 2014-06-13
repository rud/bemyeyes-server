require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'
require_relative '../app'
require_relative './rest_shared_context'
require_relative '../models/token'
require_relative '../spec/integration_spec_helper'

describe "Request" do
  include_context "rest-context"

  before(:each) do
  end

  it "can create a request" do
   register_device
   create_user
   token = log_user_in

    
    #log user out
    logoutUser_url  = "#{@servername_with_credentials}/requests"
    response = RestClient.post logoutUser_url, {'token'=> token}.to_json

    expect(response.code).to eq(200)
   end
end 
