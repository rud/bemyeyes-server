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
require 'factory_girl'
require 'uri'
require_relative '../app'
require_relative '../models/init'
require_relative '../spec/integration_spec_helper'
require_relative '../spec/factories'

I18n.config.enforce_available_locales=false
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

# http://robots.thoughtbot.com/validating-json-schemas-with-an-rspec-matcher
RSpec::Matchers.define :match_response_schema do |schema|
  match do |response|
    schema_directory = "#{Dir.pwd}/rest-specs/support/api-schemas"
    schema_path = "#{schema_directory}/#{schema}.json"
    JSON::Validator.validate!(schema_path, response.body, strict: true)
  end
end

shared_context "rest-context" do
  before(:each) do
    config = YAML.load_file('config/config.yml')
    @username = config['authentication']['username']
    @password = config['authentication']['password']
    @security_salt = config["security_salt"]
    @servername = "http://localhost:3001"
    @servername_with_credentials = "http://#{@username}:#{@password}@localhost:3001"

    @email =  create_unique_email
    @password = encrypt_password('Password1')

    User.destroy_all
    Device.destroy_all
    HelperPoint.destroy_all
    HelperRequest.destroy_all
    Request.destroy_all
    ResetPasswordToken.destroy_all
    Token.destroy_all
  end

  def create_user role ="helper", email = @email, password = @password
    createUser_url = "#{@servername_with_credentials}/users/"
    response = RestClient.post createUser_url, {'first_name' =>'first_name',
                                                'last_name'=>'last_name', 'email'=> email,
                                                'role'=> role, 'password'=> password }.to_json

    jsn = JSON.parse response.body
    id = jsn['id']
    return id
  end

  def create_unique_email
    "user_#{(Time.now.to_f*100000).to_s}@example.com"
  end

  def encrypt_password password
    AESCrypt.encrypt(password, @security_salt)
  end

  def log_user_in email = @email, password = @password, device_token = 'device_token'
    #log user in
    loginUser_url = "#{@servername_with_credentials}/users/login"
    response = RestClient.post loginUser_url, {'email' => email, 'password'=> password, 'device_token' => device_token}.to_json
    jsn = JSON.parse(response.to_s)
    token = jsn["token"]["token"]
    token
  end

  def register_device device_token = 'device_token', system_version = 'system_version'
    url = "#{@servername_with_credentials}/devices/register"
    response = RestClient.post url, {'token' =>'token_repr',
                                     'device_token'=>device_token, 'device_name'=> 'device_name',
                                     'model'=> 'model', 'system_version' => system_version,
                                     'app_version' => 'app_version', 'app_bundle_version' => 'app_bundle_version',
                                     'locale'=> 'locale', 'development' => 'true'}.to_json
    expect(response.code).to eq(200)
    json = JSON.parse(response.body)
    json["token"]
  end

end
