class App < Sinatra::Base
  register Sinatra::Namespace
  namespace '/helpers' do
    get '/waiting_request/:helper_id' do
      helper_id = params[:helper_id]
      helper  = helper_from_id(helper_id)
      waiting_request =helper.waiting_requests.first

      if waiting_request.nil?
        give_error(400, ERROR_REQUEST_NOT_FOUND, "No requests found.").to_json
      end§
      return { "id" => waiting_request.short_id }.to_json
    end

    def helper_from_id(user_id)
      helper = Helper.first(:_id => user_id)
      if helper.nil?
        give_error(400, ERROR_USER_NOT_FOUND, "No helper found.").to_json
      end
      return helper
    end
  end
end
