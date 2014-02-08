require_relative '../helpers/cron_jobs'

describe CronJobs do
	before do
		@request_double = double('request')
		@waiting_requests_double = double("waiting_requests")
		allow(@waiting_requests_double).to receive(:get_waiting_requests_from_lasts_2_minutes).and_return([@request_double])

		@helper_double = double("helper")
		allow(@helper_double).to receive(:available).and_return([])

		@request_helper = double("request_helper")
		allow(@request_helper).to receive(:send_notifications)
		allow(@request_helper).to receive(:set_sent_helper)

		@sut = CronJobs.new(@helper_double, @request_helper, double("scheduler"), @waiting_requests_double)
	end

	describe "check_requests" do
		it "gets waiting reuests from last two minutes" do
			@sut.check_requests
			expect(@waiting_requests_double).to have_received(:get_waiting_requests_from_lasts_2_minutes)
		end

		it "asks for 5 available helpers for each request" do
			@sut.check_requests
			expect(@helper_double).to have_received(:available).with(anything(),5)
		end
	end	
end
