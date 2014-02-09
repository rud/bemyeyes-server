require 'mongo_mapper'
require 'shoulda'
require_relative './integration_spec_helper'
require_relative '../models/device'
require_relative '../models/token'
require_relative '../models/user'
require_relative '../models/blind'

describe Blind do
before do
    IntegrationSpecHelper.InitializeMongo()
    @sut = Blind.new
    @sut.email = "someone@example.com"
    @sut.first_name = "firstName"
    @sut.last_name = "lastName"
    @sut.role = "blind"
    @sut.password = "password"
    @sut.save
  end

 describe "can create user" do
    it {  @sut.email.should eq("someone@example.com") }
  end
end
