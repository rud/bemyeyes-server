require_relative './thelogger_module'
require_relative './notifications/iphone_notifier'
require_relative './notifications/notification_handler'
require_relative './waiting_requests'

class RequestsHelper
  attr_accessor :iphone_production_notifier, :iphone_development_notifier
  def initialize(ua_config, logger)
    ua_prod_config = ua_config['production']
    ua_dev_config = ua_config['development']

    #setup the chain to handle notifications
    @iphone_development_notifier = IphoneDevelopmentNotifier.new ua_dev_config, logger
    @iphone_production_notifier = IphoneProductionNotifier.new ua_prod_config, logger
    @iphone_production_notifier.set_successor @iphone_development_notifier
    @notification_queue = @iphone_production_notifier
  end

  def unregister_device(development, device_token, options = {})
    if development
      @iphone_development_notifier.unregister_device device_token, options
    else
      @iphone_production_notifier.unregister_device device_token, options
    end
  end

  def register_device(development, device_token, options = {})
    if development
      @iphone_development_notifier.register_device device_token, options
    else
      @iphone_production_notifier.register_device device_token, options
    end
  end

  def collect_feedback_on_inactive_devices
    iphone_production_notifier.collect_feedback_on_inactive_devices
    iphone_development_notifier.collect_feedback_on_inactive_devices
  end

  def request_answered(payload)
    answered_requests = Request.where(:answered => true).all
    answered_request_ids = answered_requests.collect{|request| request._id}.flatten
    helper_requests = HelperRequest.where(:cancel_notification_sent => false, :$or => [{:cancelled => true}, {:request_id => {:$in => answered_request_ids}}])
    helpers = helper_requests.collect {|helper_request| helper_request.helper}.flatten
    devices = helpers.collect { |u| u.devices }.flatten
    @notification_queue.handle_cancel_contifications devices, helper_requests
  end

  def check_request (request, number_of_helpers)
    helper = Helper.new
    helpers = helper.available(request, number_of_helpers)
    devices = helpers.collect { |u| u.devices }.flatten
    @notification_queue.handle_notifications devices, request  
  end

  def check_requests(number_of_helpers)
    @waiting_requests = WaitingRequests.new
    requests = @waiting_requests.get_waiting_requests_from_lasts_2_minutes
    requests.each { |request| check_request(request, number_of_helpers) }
  end
end
