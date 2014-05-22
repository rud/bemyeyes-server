require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'

describe "Rest api" do
  before(:each) do
    config = YAML.load_file('config/config.yml')
    @username = config['authentication']['username']
    @password = config['authentication']['password']
    @security_salt = config["security_salt"]
  end
 describe "smoketest" do
      it "can get the logs" do
          url = "http://#{@username}:#{@password}@localhost:9292/log"
          response = RestClient.get url 
          response.code.should eq(200)
      end
  end
 describe "create user" do
     it "can create a user" do

         email =  "user_#{(Time.now.to_f*100000).to_s}@example.com" 
         password = AESCrypt.encrypt('Password1', @security_salt)
         url = "http://#{@username}:#{@password}@localhost:9292/users/"
         response = RestClient.post url, {'first_name' =>'first_name', 
             'last_name'=>'last_name', 'email'=> email, 
             'role'=> 'helper', 'password'=> password }.to_json
         response.code.should eq(200)
     end
 end
end
