module RequestsHelper

  #Avoids resending push notification to an already notified user.
  def self.set_sent_helper helpers, request
    helpers.each do |helper|
      HelperRequest.create! :request => request, :helper => helper
    end
  end

  def self.send_notifications request, device_tokens
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
end