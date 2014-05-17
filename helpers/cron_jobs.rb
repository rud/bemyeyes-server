require 'rufus-scheduler'
require 'active_support'
require 'active_support/deprecation'

class CronJobs

  attr_reader :helper, :request_helper, :scheduler, :waiting_requests
  def initialize(helper, request_helper, scheduler, waiting_requests, helper_point_checker)
    @helper = helper
    @request_helper = request_helper
    @scheduler = scheduler
    @waiting_requests = waiting_requests
    @helper_point_checker = helper_point_checker
  end

  def job
    return @job
  end

  def point_job
    return @point_job
  end


  def start_jobs
    @job ||= @scheduler.every('20s') do
      check_requests
    end

    @point_job ||= @scheduler.every('1d') do
      @helper_point_checker.check_helper_points
    end
  end

  def check_requests
    #1. Check for unanswered requests.
    requests = @waiting_requests.get_waiting_requests_from_lasts_2_minutes
    #For each request
    requests.each do |request|
      #2. Look for random helpers and its devices tokens
      helpers = helper.available(request, 200)
      device_tokens = helpers.collect { |u| u.devices.collect { |d| d.device_token } }.flatten
      #3. Send notification
      @request_helper.send_notifications request, device_tokens
      #4. Set notified helpers as contacted for this request.
      @request_helper.set_sent_helper helpers, request
    end
  end
end
