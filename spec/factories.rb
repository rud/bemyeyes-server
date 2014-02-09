require 'factory_girl'
require_relative './integration_spec_helper'
require_relative '../models/device'
require_relative '../models/token'
require_relative '../models/user'
require_relative '../models/blind'
require_relative '../models/helper_request'
require_relative '../models/request'
require_relative '../helpers/request_id_shortener'

FactoryGirl.define do

  # This will use the User class (Admin would have been guessed)
  factory :blind, class: User do
    first_name "Admin"
    last_name  "User"
    email "someone@example.com"
    password "password"
  end

  factory :helper, class: User do
    first_name "Admin"
    last_name  "User"
    email "someone@example.com"
    password "password"
  end

  factory :request , class: Request do
    answered false
    stopped false
    blind_rating 1
    helper_rating 2
    token "1234"
    session_id "1234"
    short_id_salt "salt"
  end
end