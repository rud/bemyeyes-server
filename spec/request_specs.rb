require 'mongo_mapper'
require 'shoulda'
require_relative './integration_spec_helper'
require_relative '../models/device'
require_relative '../models/token'
require_relative '../models/user'
require_relative '../models/blind'
require_relative '../models/helper_request'
require_relative '../models/request'

describe Request do
before do
	IntegrationSpecHelper.InitializeMongo()
    @sut = Request.new
    @sut.answered = false
    @sut.save
  end

 describe "can create Request" do
    it {  @sut.answered.should eq(false) }
  end
end