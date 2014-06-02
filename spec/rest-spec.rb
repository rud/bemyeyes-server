require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'

#I know there is a lot of duplication in this file, it shall soon be removed
#hope to not find this comment in years form now

describe "Rest api" do
  before(:each) do
    config = YAML.load_file('config/config.yml')
    @username = config['authentication']['username']
    @password = config['authentication']['password']
    @security_salt = config["security_salt"]
    @servername = "http://localhost:9292"
    @servername_with_credentials = "http://#{@username}:#{@password}@localhost:9292"
  end
 describe "smoketest" do
     it "redirects from root" do
         url = @servername
         response = RestClient.get url

         #ok so this is not the most elegant way of testing the redirect - but its ok for now
         response.should include("<title>Be My Eyes - crowdsourced help for the blind</title>")
     end
      it "can get the logs" do
          url = "#{@servername_with_credentials}/log"
          response = RestClient.get url 
          response.code.should eq(200)
      end
  end

 describe "helper points" do
     it "can get helper points" do
         email =  "user_#{(Time.now.to_f*100000).to_s}@example.com" 
         password = AESCrypt.encrypt('Password1', @security_salt)
         createUser_url = "#{@servername_with_credentials}/users/"
         response = RestClient.post createUser_url, {'first_name' =>'first_name', 
             'last_name'=>'last_name', 'email'=> email, 
             'role'=> 'helper', 'password'=> password }.to_json

         jsn = JSON.parse response.body
         id = jsn['id']

         url = "#{@servername_with_credentials}/users/helper_points/" + id
         response = RestClient.get url, {:accept => :json}
         response.code.should eq(200)

         url = "#{@servername_with_credentials}/users/helper_points_sum/" + id
         response = RestClient.get url, {:accept => :json}
         response.code.should eq(200)

         jsn = JSON.parse response.body
         sum = jsn['sum']

         sum.should eq(50)
     end

 end

 describe "update user" do
    it "can update a user after creation" do
         email =  "user_#{(Time.now.to_f*100000).to_s}@example.com" 
         password = AESCrypt.encrypt('Password1', @security_salt)
         createUser_url = "#{@servername_with_credentials}/users/"
         response = RestClient.post createUser_url, {'first_name' =>'first_name', 
             'last_name'=>'last_name', 'email'=> email, 
             'role'=> 'helper', 'password'=> password }.to_json

         jsn = JSON.parse response.body
         id = jsn['id']

         url = "#{@servername_with_credentials}/users/" + id
         response = RestClient.put url, {'first_name' =>'my first_name', 
             'last_name'=>'last_name', 'email'=> email, 
             'role'=> 'helper', 'password'=> password }.to_json

         response.code.should eq(200)
    end 
 end

 describe "snooze" do
    it "can create user and then snooze" do
         email =  "user_#{(Time.now.to_f*100000).to_s}@example.com" 
         password = AESCrypt.encrypt('Password1', @security_salt)
         createUser_url = "#{@servername_with_credentials}/users/"
         response = RestClient.post createUser_url, {'first_name' =>'first_name', 
             'last_name'=>'last_name', 'email'=> email, 
             'role'=> 'helper', 'password'=> password }.to_json

         jsn = JSON.parse response.body
         id = jsn['id']

         url = "#{@servername_with_credentials}/users/"+id + "/snooze/1h"
         response = RestClient.put url, {}.to_json
         response.code.should eq(200)

    end 
 end
 describe "create user" do
     it "can create a user and get it" do
         email =  "user_#{(Time.now.to_f*100000).to_s}@example.com" 
         password = AESCrypt.encrypt('Password1', @security_salt)
         createUser_url = "#{@servername_with_credentials}/users/"
         response = RestClient.post createUser_url, {'first_name' =>'first_name', 
             'last_name'=>'last_name', 'email'=> email, 
             'role'=> 'helper', 'password'=> password }.to_json

         jsn = JSON.parse response.body
         id = jsn['id']

         getUser_url = "#{@servername_with_credentials}/users/" + id
         response = RestClient.get getUser_url, {:accept => :json}
         response.code.should eq(200)

         jsn = JSON.parse response.body
         jsn['first_name'].should eq('first_name')
     end

     it "can create a user" do
         email =  "user_#{(Time.now.to_f*100000).to_s}@example.com" 
         password = AESCrypt.encrypt('Password1', @security_salt)
         url = "#{@servername_with_credentials}/users/"
         response = RestClient.post url, {'first_name' =>'first_name', 
             'last_name'=>'last_name', 'email'=> email, 
             'role'=> 'helper', 'password'=> password }.to_json
         response.code.should eq(200)
     end

     it "can create user,log in and log out" do
         email =  "user_#{(Time.now.to_f*100000).to_s}@example.com" 
         password = AESCrypt.encrypt('Password1', @security_salt)

         #create user
         createUser_url = "#{@servername_with_credentials}/users/"
         RestClient.post createUser_url, {'first_name' =>'first_name', 
             'last_name'=>'last_name', 'email'=> email, 
             'role'=> 'helper', 'password'=> password }.to_json

         #log user in
         loginUser_url = "#{@servername_with_credentials}/users/login"
         response = RestClient.post loginUser_url, {'email' => email, 'password'=> password}.to_json
         jsn = JSON.parse(response.to_s)
         token = jsn["token"]["token"]

         #log user out
         logoutUser_url  = "#{@servername_with_credentials}/users/logout"
         response = RestClient.put logoutUser_url, {'token'=> token}.to_json

         response.code.should eq(200)
     end
 end
end