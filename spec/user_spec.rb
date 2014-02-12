require 'mongo_mapper'
require 'shoulda'
require 'factory_girl'

require_relative './factories'
require_relative './integration_spec_helper'
require_relative '../models/device'
require_relative '../models/token'
require_relative '../models/user'
require_relative '../models/blind'

# rspec
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe Blind do
  before do
    IntegrationSpecHelper.InitializeMongo()
    @sut = build(:blind)
    
    @sut.save
  end

 describe "can create user" do
    it {  @sut.first_name.should eq("Blind") }
  end
end
