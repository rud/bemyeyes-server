require 'rufus-scheduler'
require 'active_support'
require 'active_support/core_ext'

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

  def check_request (request)
    helpers = helper.available(request, 200)
    device_tokens = helpers.collect { |u| u.devices.collect { |d| d.device_token } }.flatten
    @request_helper.send_notifications request, device_tokens
    @request_helper.set_sent_helper helpers, request
  end

  def check_requests
    requests = @waiting_requests.get_waiting_requests_from_lasts_2_minutes
    requests.each { |request| check_request request }
  end
end
