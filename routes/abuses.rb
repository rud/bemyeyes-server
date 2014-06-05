class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin devices namespace
  namespace '/abuse' do
    def check_and_raise_if_blank_string(theStr, name)
      if theStr.nil? or theStr.length == 0
        raise "#{name} can not be empty or nil "
      end
    end

    def is_logged_in(token)
      token = Token.first(:token => token)
      !token.nil?
    end
    def get_reporter_role(token)
      token = Token.first(:token => token)
      token.user.role
    end

    post '/report' do
      begin
        body_params = JSON.parse(request.body.read)
        token_repr = body_params["token"]
        request_id = body_params["request_id"]
        reason = body_params["reason"]
        check_and_raise_if_blank_string token_repr, "token"
        check_and_raise_if_blank_string request_id, "request_id"
        check_and_raise_if_blank_string reason, "reason"
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid. " + e.message).to_json
      end

      if !is_logged_in token_repr
        give_error(401, ERROR_NOT_AUTHORIZED, "Reporter should be logged in").to_json
      end
      begin
        reporter = get_reporter_role token_repr
        request = Request.first(:id => request_id)
        abuse_report = AbuseReport.new
        abuse_report.request = request
        abuse_report.reason = reason
        abuse_report.reporter = reporter
        abuse_report.blind = request.blind
        abuse_report.helper = request.helper
        abuse_report.save!

      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "Unable to create abuse report" + e.message).to_json
      end
    end
  end
end
