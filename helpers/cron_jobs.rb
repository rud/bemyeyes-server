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
      RequestsHelper.send_notifications request, device_tokens
      #4. Set notified helpers as contacted for this request.
      RequestsHelper.set_sent_helper helpers, request
    end
  end

end
