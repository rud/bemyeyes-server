class App < Sinatra::Base
  register Sinatra::Namespace
  namespace '/helpers' do
    get '/waiting_request/:helper_id' do
      helper_id = params[:helper_id]
      helper  = helper_from_id(helper_id)
      waiting_request =helper.waiting_requests.first
      if waiting_request.nil?
        return { "id" => 0 }.to_json
      end
      return { "id" => waiting_request.short_id }.to_json
    end
  end
end
