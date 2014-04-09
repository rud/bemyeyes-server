require 'rest_client'
require 'shoulda'
require 'yaml'

describe "Rest api" do
  before(:each) do
    config = YAML.load_file('config/config.yml')
    @username = config['authentication']['username']
    @password = config['authentication']['password']
  end
  describe "User api" do 
    before(:each) do
      config = YAML.load_file('config/config.yml')
      @username = config['authentication']['username']
      @password = config['authentication']['password']
    end
    
    it "Should return a user" do
      response = RestClient::Request.new(
        :method => :get,
        :url => "http://stagingapi.bemyeyes.org/users/1",
        :user => @username,
        :password => @password,
        :headers => { :accept => :json,
          :content_type => :json }
          ).execute 
      response.code.should eq(200)
    end
  end
end
