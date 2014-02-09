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

		before(:each) do
			@sut.check_requests
		end
		
		it "gets waiting reuests from last two minutes" do
			expect(@waiting_requests_double).to have_received(:get_waiting_requests_from_lasts_2_minutes)
		end

		it "asks for 5 available helpers for each request" do
			expect(@helper_double).to have_received(:available).with(anything(),5)
		end

		it "Sends notification" do
			expect(@request_helper).to have_received(:send_notifications)
		end

		it "Sets notified helpers as contacted for this request." do
			expect(@request_helper).to have_received(:set_sent_helper)
		end
	end	
end
