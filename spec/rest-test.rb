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

     it "can create user,log in and log out" do
         email =  "user_#{(Time.now.to_f*100000).to_s}@example.com" 
         password = AESCrypt.encrypt('Password1', @security_salt)

         #create user
         createUser_url = "http://#{@username}:#{@password}@localhost:9292/users/"
         RestClient.post createUser_url, {'first_name' =>'first_name', 
             'last_name'=>'last_name', 'email'=> email, 
             'role'=> 'helper', 'password'=> password }.to_json

         #log user in
         loginUser_url = "http://#{@username}:#{@password}@localhost:9292/users/login"
         response = RestClient.post loginUser_url, {'email' => email, 'password'=> password}.to_json
         jsn = JSON.parse(response.to_s)
         token = jsn["token"]["token"]

         #log user out
         logoutUser_url  = "http://#{@username}:#{@password}@localhost:9292/users/logout"
         response = RestClient.put logoutUser_url, {'token'=> token}.to_json

         response.code.should eq(200)
     end
 end
end
