require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'

require_relative '../../app'
require_relative '../../models/token'
require_relative '../../spec/rest-specs/rest_shared_context'
require_relative '../integration_spec_helper'

describe "log device in" do
    include_context "rest-context"

    it "can create a device without user token" do  
        url = "#{@servername_with_credentials}/devices/register"
        response = RestClient.post url, {'token' =>'token_repr', 
                                         'device_token'=>'device_token', 'device_name'=> 'device_name', 
                                         'model'=> 'model', 'system_version' => 'system_version', 
                                         'app_version' => 'app_version', 'app_bundle_version' => 'app_bundle_version',
                                         'locale'=> 'locale', 'development' => 'development'}.to_json
        response.code.should eq(200)
    end

    it "cannot log user in without device token" do 
        #create user
        create_user
        #log user in
        loginUser_url = "#{@servername_with_credentials}/users/login"
        expect{RestClient.post loginUser_url, 
        {'email' => @email, 'password'=> @password}.to_json}
        .to raise_error(RestClient::BadRequest)
        
       

    end 

    it "can log a user in with a device token" do
    end


    it "can log user out with token and token is deleted" do
        #create user
        create_user
        #log user in
        loginUser_url = "#{@servername_with_credentials}/users/login"
        response = RestClient.post loginUser_url, 
        {'email' => @email, 'password'=> @password, 'device_token' => 'device_token'}.to_json
        jsn = JSON.parse(response.to_s)
        token = jsn["token"]["token"]

        #log user out
        logoutUser_url  = "#{@servername_with_credentials}/users/logout"
        response = RestClient.put logoutUser_url, {'token'=> token}.to_json

        Token.all(:token => token).count.should eq(0)
    end
end
