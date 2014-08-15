require 'factory_girl'
require_relative './integration_spec_helper'
require_relative '../models/device'
require_relative '../models/token'
require_relative '../models/user'
require_relative '../models/blind'
require_relative '../models/helper'
require_relative '../models/helper_request'
require_relative '../models/request'

FactoryGirl.define do

  factory :blind, class: Blind do
    first_name "Blind"
    last_name  "User"
    email {"blind_#{(Time.now.to_f*100000).to_s}@example.com" }
    password "password"
    role "blind"
  end

  factory :helper, class: Helper do
    first_name "Helper"
    last_name  "User"
    email {"helper_#{(Time.now.to_f*100000).to_s}@example.com" }
    password "password"
    role "helper"
  end

  factory :request , class: Request do
    answered false
    stopped false
    blind_rating 1
    helper_rating 2
    token "1234"
    session_id "1234"
    short_id_salt "salt"
    helper
    blind
  end

  factory :device, class: Device do
    device_token "device_token"
  end

end
