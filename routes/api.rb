class App < Sinatra::Base
  register Sinatra::Namespace

  namespace '/api' do
    before do
      protected!
    end

    # Create new request
    post '/request' do
      content_type 'application/json'

      begin
        session_properties = { OpenTok::SessionPropertyConstants::P2P_PREFERENCE => "enabled" }
        session_id = OpenTokSDK.create_session(NIL, session_properties)
        token = OpenTokSDK.generateToken :session_id => session_id
      rescue Exception => e
        halt 400,
        {'Content-Type' => 'application/json'},
        { "error" => {
            "message" => "Could not create session.",
            "detailed_message" => e.message
          }
        }.to_json
      end
      
      # Get body
      begin
        body_params = JSON.parse(request.body.read)
        name = body_params["name"]
      rescue Exception => e
        name = NIL
      end

      # Store request in database
      request = Request.new
      request.session_id = session_id
      request.token = token
      request.name = name
      request.save!
      
      # Send notification
      notification_args_name = (name.nil? || name.empty?) ? "Someone" : name
      notification = {
        :tags => ['helper'],
        :aps => {
          :alert => {
            :"loc-key" => "PUSH_NOTIFICATION_ANSWER_REQUEST_MESSAGE",
            :"loc-args" => [ notification_args_name ],
            :"action-loc-key" => "PUSH_NOTIFICATION_ANSWER_REQUEST_ACTION",
            :short_id => request.short_id,
          },
          :sound => "default"
        }
      }
  		Urbanairship.push(notification)
    
      { "short_id" => request.short_id,
        "opentok" => {
          "session_id" => request.session_id,
          "token" => request.token
        }
      }.to_json
    end

    # Get a request
    get '/request/:short_id' do
      content_type 'application/json'

      request = Request.first(:short_id => params[:short_id])
      if request
        { "opentok" => {
            "session_id" => request.session_id,
            "token" => request.token
          }
        }.to_json
      else
        halt 400,
        {'Content-Type' => 'application/json'},
        { "error" => {
            "message" => "Request not found.",
          }
        }.to_json
      end
    end
  end
end