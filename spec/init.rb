require 'active_support'
require 'active_support/core_ext'
require 'mongo_mapper'
require 'factory_girl'
require_relative '../helpers/thelogger_module'
require_relative './factories'
require_relative '../models/init'
require_relative './integration_spec_helper'
require_relative '../helpers/helper_point_checker'
require_relative '../helpers/reset_password'
require_relative '../helpers/waiting_requests'

I18n.config.enforce_available_locales=false
