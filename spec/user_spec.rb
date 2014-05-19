require 'mongo_mapper'
require 'shoulda'
require 'factory_girl'
require 'rack/test'
require 'bundler'

require_relative '../app'
require_relative './factories'
require_relative './integration_spec_helper'
require_relative '../models/device'
require_relative '../models/token'
require_relative '../models/user'
require_relative '../models/blind'
require_relative '../models/helper'

# rspec
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe Blind do
  include Rack::Test::Methods

  before do
    IntegrationSpecHelper.InitializeMongo()
    @sut = build(:blind)
    
    @sut.save
  end

 describe "can create user" do
    it {  @sut.first_name.should eq("Blind") }
  end
end
