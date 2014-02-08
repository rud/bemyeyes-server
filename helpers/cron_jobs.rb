require 'rufus-scheduler'
require 'active_support'

class CronJobs

  attr_reader :helper, :request_helper
  def initialize(helper, request_helper)
    @helper = helper
    @request_helper = request_helper
  end


  def scheduler
    @scheduler ||= Rufus::Scheduler.new
  end

  def job
    return @job
  end

  def start_jobs
    @job ||= scheduler.every('20s') do
      check_requests
    end
  end

  def check_requests
    #1. Check for unanswered requests.
    requests = Request.where(:stopped => false, :answered => false, :created_at.lte => 2.minutes.ago).all
    #For each request
    requests.each do |request|
      #2. Look for random helpers and its devices tokens
      helpers = @helper.available(request, 5)
      device_tokens = helpers.collect { |u| u.devices.collect { |d| d.device_token } }.flatten
      #3. Send notification
      @request_helper.send_notifications request, device_tokens
      #4. Set notified helpers as contacted for this request.
      @request_helper.set_sent_helper helpers, request
    end
  end

end
