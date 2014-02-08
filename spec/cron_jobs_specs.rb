require_relative '../helpers/cron_jobs'

describe CronJobs do
	before do
		@waiting_requests_double = double("waiting_requests")
		allow(@waiting_requests_double).to receive(:get_waiting_requests_from_lasts_2_minutes).and_return([])
		@sut = CronJobs.new(double("helper"), double("request_helper"), double("scheduler"), @waiting_requests_double)
	end

	describe "check_requests" do
		it "gets waiting reuests from last two minutes" do
			@sut.check_requests
			expect(@waiting_requests_double).to have_received(:get_waiting_requests_from_lasts_2_minutes)
		end

	end	
end
