require 'rubygems'
require 'sinatra'
require "sinatra/config_file"
require 'sinatra/namespace'
require 'opentok'
require 'mongo_mapper'
require 'json'
require 'urbanairship'
require 'aescrypt'
require 'bcrypt'
require 'json-schema'
require 'rufus-scheduler'
require_relative 'helpers/requests_helper'
require_relative 'models/init'
require_relative 'routes/init'
require_relative 'helpers/error_codes'
require_relative 'helpers/api_error'
require_relative 'helpers/request_id_shortener'
require_relative 'helpers/cron_jobs'
require_relative 'helpers/thelogger_module'
require_relative 'helpers/waiting_requests'
require_relative 'helpers/date_helper'
require_relative 'helpers/helper_point_checker'

class App < Sinatra::Base
  register Sinatra::ConfigFile
  
  config_file 'config/config.yml'
  
  # Do any configurations
  configure do
    set :environment, :development
    set :show_exceptions, false
    set :app_file, __FILE__
    set :config, YAML.load_file('config/config.yml') rescue nil || {}
    set :scheduler, Rufus::Scheduler.new
    
    TheLogger.log.level = Logger::DEBUG  # could be DEBUG, ERROR, FATAL, INFO, UNKNOWN, WARN
    TheLogger.log.formatter = proc { |severity, datetime, progname, msg| "[#{severity}] #{datetime.strftime('%Y-%m-%d %H:%M:%S')} : #{msg}\n" }
    
    opentok_config = settings.config['opentok']
    OpenTokSDK = OpenTok::OpenTokSDK.new opentok_config['api_key'], opentok_config['api_secret']
    
    ua_config = settings.config['urbanairship']
    ua_prod_config = ua_config['production']
    ua_dev_config = ua_config['development']
    Urbanairship.application_key = ua_config['is_production'] ? ua_prod_config['app_key'] : ua_dev_config['app_key']
    Urbanairship.application_secret = ua_config['is_production'] ? ua_prod_config['app_secret'] : ua_dev_config['app_secret']
    Urbanairship.master_secret = ua_config['is_production'] ? ua_prod_config['master_secret'] : ua_dev_config['master_secret']
    Urbanairship.request_timeout = 5 # default

    db_config = settings.config['database']
    MongoMapper.connection = Mongo::Connection.new(db_config['host'])
    MongoMapper.database = db_config['name']
    MongoMapper.connection[db_config['name']].authenticate(db_config['username'], db_config['password'])
    
    cron_job = CronJobs.new(Helper.new, RequestsHelper.new, Rufus::Scheduler.new, WaitingRequests.new, HelperPointChecker.new)
    cron_job.start_jobs
  end

  # Protect anything but the root
  before /^\/.+/ do
    protected!
  end
  before do
    content_type 'application/json'
  end
  
  # Root route
  get '/?' do
    redirect settings.config['redirect_root']
  end
  
  get '/log' do
    File.read("log/app.log")
  end  
  # Handle errors
  error do
    content_type :json
    status 500

    e = env["sinatra.error"]
    return { "result" => "error", "message" => e.message }.to_json
  end

  # Check if ww are authorized
  def authorized?
    auth_config = settings.config['authentication']
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [auth_config['username'], auth_config['password']]
  end

  # Require authentication
  def protected!
    return if authorized?
    content_type :json
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, create_error_hash(ERROR_NOT_AUTHORIZED, "Not authorized.").to_json
  end
  
  # 404 not found
  not_found do
    content_type :json
    give_error(404, ERROR_RESOURCE_NOT_FOUND, "Resource not found.").to_json
  end
  
end
