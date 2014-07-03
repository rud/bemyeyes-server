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

  def ua_feedback_job
    return @ua_feedback_job
  end


  def start_jobs
    @job ||= @scheduler.every('20s') do
      @request_helper.check_requests 200
    end

    @point_job ||= @scheduler.every('1d') do
      @helper_point_checker.check_helper_points
    end

    @ua_feedback_job ||= @scheduler.every('1d') do
      @request_helper.collect_feedback_on_inactive_devices
      TheLogger.log.info 'gathered feedback for inactive devices'
    end
  end
end
