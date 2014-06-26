require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'
require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'
require_relative '../app'
require_relative '../models/init'
require_relative '../spec/integration_spec_helper'

I18n.config.enforce_available_locales=false

shared_context "rest-context" do
  before(:each) do
    config = YAML.load_file('config/config.yml')
    @username = config['authentication']['username']
    @password = config['authentication']['password']
    @security_salt = config["security_salt"]
    @servername = "http://localhost:9292"
    @servername_with_credentials = "http://#{@username}:#{@password}@localhost:9292"

    @email =  "user_#{(Time.now.to_f*100000).to_s}@example.com"
    @password = AESCrypt.encrypt('Password1', @security_salt)
  end

  def create_user
    createUser_url = "#{@servername_with_credentials}/users/"
    response = RestClient.post createUser_url, {'first_name' =>'first_name',
                                                'last_name'=>'last_name', 'email'=> @email,
                                                'role'=> 'helper', 'password'=> @password }.to_json

    jsn = JSON.parse response.body
    id = jsn['id']
    return id
  end

  def log_user_in
    #log user in
    loginUser_url = "#{@servername_with_credentials}/users/login"
    response = RestClient.post loginUser_url, {'email' => @email, 'password'=> @password, 'device_token' => 'device_token'}.to_json
    jsn = JSON.parse(response.to_s)
    token = jsn["token"]["token"]
    token
  end

  def register_device
    url = "#{@servername_with_credentials}/devices/register"
    response = RestClient.post url, {'token' =>'token_repr',
                                     'device_token'=>'device_token', 'device_name'=> 'device_name',
                                     'model'=> 'model', 'system_version' => 'system_version',
                                     'app_version' => 'app_version', 'app_bundle_version' => 'app_bundle_version',
                                     'locale'=> 'locale', 'development' => 'true'}.to_json
    expect(response.code).to eq(200)
    json = JSON.parse(response.body)
    json["token"]
  end

end
