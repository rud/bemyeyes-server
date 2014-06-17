require_relative './thelogger_module'

class RequestsHelper

  def initialize
  end
  #Avoids resending push notification to an already notified user.
  def set_sent_helper helpers, request
    helpers.each do |helper|
      HelperRequest.create! :request => request, :helper => helper
    end
  end

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
  end

  def check_request (request, number_of_helpers)
    helper = Helper.new
    helpers = helper.available(request, number_of_helpers)
    device_tokens = helpers.collect { |u| u.devices.collect { |d| d.device_token } }.flatten
    @request_helper.send_notifications request, device_tokens
    @request_helper.set_sent_helper helpers, request
  end

  def check_requests number_of_helpers
    requests = @waiting_requests.get_waiting_requests_from_lasts_2_minutes
    requests.each { |request| check_request request number_of_helpers }
  end
end