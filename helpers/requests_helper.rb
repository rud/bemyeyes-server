require_relative './thelogger_module'
require_relative './notifications/iphone_notifier'
require_relative './notifications/notification_handler'
require_relative './waiting_requests'

class RequestsHelper
  def initialize(ua_config, logger)
    ua_prod_config = ua_config['production']
    ua_dev_config = ua_config['development']

    #setup the chain to handle notifications
    @iphone_development_notifier = IphoneDevelopmentNotifier.new ua_dev_config, logger
    @iphone_production_notifier = IphoneProductionNotifier.new ua_prod_config, logger
    @iphone_production_notifier.set_successor @iphone_development_notifier
    @notification_queue = @iphone_production_notifier
  end
  def register_device(development, device_token, options = {})
   if development
     @iphone_development_notifier.register_device device_token, options
   else
    @iphone_production_notifier.register_device device_token, options
  end
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
