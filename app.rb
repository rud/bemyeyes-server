require 'rubygems'
require 'sinatra'
require "sinatra/config_file"
require 'sinatra/namespace'
require 'opentok'
require 'mongo_mapper'
require 'json'
require 'urbanairship'
require_relative 'error_codes'
require_relative 'models/init'
require_relative 'routes/init'
require_relative 'helpers/request_id_shortener'

class App < Sinatra::Base
  register Sinatra::ConfigFile
  
  config_file 'config/config.yml'

  # Do any configurations
  configure do
    set :environment, :development
    set :app_file, __FILE__
    
    Log = Logger.new('sinatra.log')
    Log.level  = Logger::INFO 
    
    @@config = YAML.load_file('config/config.yml') rescue nil || {}
    
    opentok_config = @@config['opentok']
    OpenTokSDK = OpenTok::OpenTokSDK.new opentok_config['api_key'], opentok_config['api_secret']
    
    ua_config = @@config['urbanairship']
    ua_prod_config = ua_config['production']
    ua_dev_config = ua_config['development']
    Urbanairship.application_key = ua_config['is_production'] ? ua_prod_config['app_key'] : ua_dev_config['app_key']
    Urbanairship.application_secret = ua_config['is_production'] ? ua_prod_config['app_secret'] : ua_dev_config['app_secret']
    Urbanairship.master_secret = ua_config['is_production'] ? ua_prod_config['master_secret'] : ua_dev_config['master_secret']
    Urbanairship.request_timeout = 5 # default

    db_config = @@config['database']
    MongoMapper.connection = Mongo::Connection.new(db_config['host'])
    MongoMapper.database = db_config['name']
    MongoMapper.connection[db_config['name']].authenticate(db_config['username'], db_config['password'])
  end

  # Check if ww are authorized
  def authorized?
    auth_config = @@config['authentication']
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [auth_config['username'], auth_config['password']]
  end

  # Require authentication
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end
end