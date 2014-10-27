require 'rufus-scheduler'
require 'active_support'
require 'active_support/core_ext'

class CronJobs

  attr_reader :helper, :request_helper, :scheduler, :waiting_requests
  def initialize(helper, request_helper, scheduler, waiting_requests, helper_point_checker, db_name)
    @helper = helper
    @request_helper = request_helper
    @scheduler = scheduler
    @waiting_requests = waiting_requests
    @helper_point_checker = helper_point_checker
    @db_name = db_name
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

   def mongo_map_reduce_job
    return @mongo_map_reduce_job
  end

  def start_jobs
    @job ||= @scheduler.every('5s') do
      @request_helper.check_requests 1
    end

    @point_job ||= @scheduler.every('1d') do
      @helper_point_checker.check_helper_points
    end

    @ua_feedback_job ||= @scheduler.every('1d') do
      @request_helper.collect_feedback_on_inactive_devices
      TheLogger.log.info 'gathered feedback for inactive devices'
    end

    @mongo_map_reduce_job ||= @scheduler.every('1d') do
      `mongo #{@db_name} ./../mongo_queries/map_reduce_ios_version.js`
      TheLogger.log.info 'ran map reduce on mongo'
    end
  end
end
