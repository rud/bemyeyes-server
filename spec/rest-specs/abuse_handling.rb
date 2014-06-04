require 'rest_client'
require 'shoulda'
require 'yaml'
require 'aescrypt'
require 'bcrypt'
require 'base64'
require_relative '../../spec/rest-specs/rest_shared_context'

describe "abuse handling" do
    #include token and helper_request id
    include_context "rest-context"
    it "will let blind report abuse" do
      register_device
      id = create_user
    end
end 
