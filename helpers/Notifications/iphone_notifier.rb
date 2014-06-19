require_relative  './notification_handler'

module IphoneNotifier
  def send_notifications request, device_tokens
    # Create notification
    user = request.blind
    notification_args_name = user.to_s
    notification = {
      :device_tokens => device_tokens,
      :aps => {
        :alert => {
          :"loc-key" => "PUSH_NOTIFICATION_ANSWER_REQUEST_MESSAGE",
          :"loc-args" => [ notification_args_name ],
          :"action-loc-key" => "PUSH_NOTIFICATION_ANSWER_REQUEST_ACTION",
          :short_id => request.short_id,
          },
          :sound => "default"
        }
      }
    # Send notification
    Urbanairship.push(notification)
     device_tokens.each do |token|
       TheLogger.log.info("sending request to token device " + token)
     end
  end

  def setup_urban_airship(ua_config, logger)
    Urbanairship.application_key =  ua_config['app_key']
    Urbanairship.application_secret = ua_config['app_secret']
    Urbanairship.master_secret = ua_config['master_secret']
    Urbanairship.request_timeout = 5 # default
    Urbanairship.logger = logger.log
  end
end

class IphoneProductionNotifier < NotificationHandler
  include IphoneNotifier

  def initialize(ua_config, logger)
    setup_urban_airship ua_config, logger
  end

  def include_device? device
    not device.development
  end

end

class IphoneDevelopmentNotifier < NotificationHandler
  include IphoneNotifier

  def initialize(ua_config, logger)
    setup_urban_airship ua_config, logger
  end

  def include_device? device
    device.development
  end
end
