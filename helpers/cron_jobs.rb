require 'rufus-scheduler'

module CronJobs
  def self.scheduler
    @scheduler ||= Rufus::Scheduler.new
  end

  def self.job
    return @job
  end

  def self.start_jobs
    @job ||= scheduler.every('20s') do
      check_requests
    end
  end

  def self.check_requests
    #1. Check for unanswered requests.
    requests = Request.unattended.all
    #For each request
    requests.each do |request|
      #2. Look for random helpers and its devices tokens
      helpers = Helper.available(request, 5)
      device_tokens = helpers.collect { |u| u.devices.collect { |d| d.device_token } }.flatten
      #3. Send notification
      send_notifications request, device_tokens
      #4. Set notified helpers as contacted for this request.
      set_sent_helper helpers, request
    end

  end

  private
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
