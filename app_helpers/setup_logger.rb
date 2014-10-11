class App < Sinatra::Base
  def self.access_logger
    @access_logger||= ::Logger.new(access_log, 'daily')
    @access_logger
  end

  def self.error_logger
    @error_logger ||= ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'..','log','error.log'),"a+")
    @error_logger
  end

  def self.access_log
    @access_log ||= ::File.join(::File.dirname(::File.expand_path(__FILE__)),'..','log','access.log')
    @access_log
  end

  def error_log
    @error_log ||= ::File.new("log/error.log","a+")
    @error_log
  end

  def self.setup_logger
    #logging according to: http://spin.atomicobject.com/2013/11/12/production-logging-sinatra/
    ::Logger.class_eval { alias :write :'<<' }
    error_logger.sync = true
    TheLogger.log.level = Logger::DEBUG  # could be DEBUG, ERROR, FATAL, INFO, UNKNOWN, WARN
    TheLogger.log.formatter = proc { |severity, datetime, progname, msg| "[#{severity}] #{datetime.strftime('%Y-%m-%d %H:%M:%S')} : #{msg}\n" }
  end


  # Do any configurations
  configure do
    set :dump_errors, true
    enable :logging

    use ::Rack::CommonLogger, access_logger
  end
end
