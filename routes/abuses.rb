class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin devices namespace
  namespace '/abuse' do
    def is_blank_string?(theStr)
      theStr.nil? or theStr.length == 0
    end

    # Register device
    post '/report' do
      begin
        body_params = JSON.parse(request.body.read)
        token_repr = body_params["token"]
        helper_request_id = body_params["helper_request_id"]
        reason = body_params["reason"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid. " + e.message).to_json
      end
      begin
        helper_request = HelperRequest.first(:id => helper_request_id)
        abuse_report = AbuseReport.new
        abuse_report.helper_request = helper_request
        abuse_report.reason = reason
        abuse_report.save!
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "Unable to create abuse report" + e.message).to_json
      end
    end
  end
end
