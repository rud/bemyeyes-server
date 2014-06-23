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
require_relative 'helpers/cron_jobs'
require_relative 'helpers/thelogger_module'
require_relative 'helpers/waiting_requests'
require_relative 'helpers/date_helper'
require_relative 'helpers/helper_point_checker'
I18n.config.enforce_available_locales=false
class App < Sinatra::Base
  register Sinatra::ConfigFile

  config_file 'config/config.yml'
  #logging according to: http://spin.atomicobject.com/2013/11/12/production-logging-sinatra/
  ::Logger.class_eval { alias :write :'<<' }
  access_log = ::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','access.log')
  access_logger = ::Logger.new(access_log, 'daily')
  error_logger = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'log','error.log'),"a+")
  error_logger.sync = true

  # Do any configurations
  configure do
    set :environment, :development
    set :dump_errors, true
    set :raise_errors, true
    set :show_exceptions, true
    enable :logging
    set :app_file, __FILE__
    set :config, YAML.load_file('config/config.yml') rescue nil || {}
    set :scheduler, Rufus::Scheduler.new
    Encoding.default_external = 'UTF-8'

    TheLogger.log.level = Logger::DEBUG  # could be DEBUG, ERROR, FATAL, INFO, UNKNOWN, WARN
    TheLogger.log.formatter = proc { |severity, datetime, progname, msg| "[#{severity}] #{datetime.strftime('%Y-%m-%d %H:%M:%S')} : #{msg}\n" }

    use ::Rack::CommonLogger, access_logger

    opentok_config = settings.config['opentok']
    OpenTokSDK = OpenTok::OpenTok.new opentok_config['api_key'], opentok_config['api_secret']

    db_config = settings.config['database']
    MongoMapper.connection = Mongo::Connection.new(db_config['host'])
    MongoMapper.database = db_config['name']
    if db_config.has_key? 'username'
      MongoMapper.connection[db_config['name']].authenticate(db_config['username'], db_config['password'])
    else
     MongoMapper.connection[db_config['name']]
    end

    ua_config = settings.config['urbanairship']
    @requests_helper = RequestsHelper.new ua_config, TheLogger
    cron_job = CronJobs.new(Helper.new, @requests_helper, Rufus::Scheduler.new, WaitingRequests.new, HelperPointChecker.new)
    cron_job.start_jobs
  end
  error_log = ::File.new("log/error.log","a+")

  before  do
    env["rack.errors"] = error_log
  end

  # Protect anything but the root
  before /^(?!\/reset-password)\/.+$/ do
    protected!
  end

  before /^(?!\/((reset-password)|(log)))\/.+$/ do
    content_type 'application/json'
  end

  # Root route
  get '/?' do
    redirect settings.config['redirect_root']
  end

  get '/log/' do
    log_file = params[:file] || "app"
    log_file = "log/#{log_file}.log"

    if !File.exists? log_file
      log_file = "log/app.log"
    end
    File.read(log_file).gsub!(/\[/,"<br/>[").gsub("[INFO]", "<span style='color:green'>[INFO]</span>").gsub("[ERROR]", "<span style='color:red'>[ERROR]</span>")
  end
  # Handle errors
  error do
    content_type :json
    status 500

    e = env["sinatra.error"]
    TheLogger.log.error(e)
    TheLogger.log.error("testing")
    return { "result" => "error", "message" => e.message }.to_json
  end

  # Check if ww are authorized
  def authorized?
    auth_config = settings.config['authentication']
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [auth_config['username'], auth_config['password']]
  end

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
