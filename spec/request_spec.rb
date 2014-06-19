require 'mongo_mapper'
require 'shoulda'
require 'factory_girl'

require_relative './factories'
require_relative './integration_spec_helper'
require_relative '../models/device'
require_relative '../models/token'
require_relative '../models/user'
require_relative '../models/blind'
require_relative '../models/helper'
require_relative '../models/helper_request'
require_relative '../models/request'


RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

describe Request do
before do
	IntegrationSpecHelper.InitializeMongo()
    
    @sut = build(:request)
    @sut.save
  end

 describe "can create Request" do
    it { expect(@sut.answered).to eq(false) }
  end
end
