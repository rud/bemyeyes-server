require 'rest_client'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'
require_relative './rest_shared_context'

describe "Rest api" do
    include_context "rest-context"
    describe "update user" do
        it "can update a user after creation" do
            id = create_user 
            url = "#{@servername_with_credentials}/users/" + id
            response = RestClient.put url, {'first_name' =>'my first_name', 
                                            'last_name'=>'last_name', 'email'=> @email, 
                                            'role'=> 'helper', 'password'=> @password }.to_json

            expect(response.code).to eq(200)
        end 
    end

    describe "snooze" do
        it "can create user and then snooze" do
            id = create_user 

            url = "#{@servername_with_credentials}/users/"+id + "/snooze/1h"
            response = RestClient.put url, {}.to_json
            expect(response.code).to eq(200)

        end 
    end
    describe "create user" do
        it "can create a user and get it" do
            id = create_user 

            getUser_url = "#{@servername_with_credentials}/users/" + id
            response = RestClient.get getUser_url, {:accept => :json}
            expect(response.code).to eq(200)

            jsn = JSON.parse response.body
            expect(jsn['first_name']).to eq('first_name')
        end

        it "can create a user" do
            url = "#{@servername_with_credentials}/users/"
            response = RestClient.post url, {'first_name' =>'first_name', 
                                             'last_name'=>'last_name', 'email'=> @email, 
                                             'role'=> 'helper', 'password'=> @password }.to_json
            expect(response.code).to eq(200)
        end

        it "can create user,log in and log out" do
            #create user
            create_user
            token = log_user_in
            #log user out
            logoutUser_url  = "#{@servername_with_credentials}/users/logout"
            response = RestClient.put logoutUser_url, {'token'=> token}.to_json

            expect(response.code).to eq(200)
        end
    end
end
