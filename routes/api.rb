class App < Sinatra::Base
  register Sinatra::Namespace

  namespace '/api' do
    before do
      protected!
    end

    # Create new request
    post '/request' do
      content_type 'application/json'
      
      # Get name from body
      begin
        body_params = JSON.parse(request.body.read)
        name = body_params["name"]
      rescue Exception => e
        name = NIL
      end

      begin
        session_properties = { OpenTok::SessionPropertyConstants::P2P_PREFERENCE => "enabled" }
        session_id = OpenTokSDK.create_session(NIL, session_properties)
        token = OpenTokSDK.generateToken :session_id => session_id
      rescue Exception => e
        halt 500,
        {'Content-Type' => 'application/json'},
        create_error_hash(ERROR_REQUEST_SESSION_NOT_CREATED, "The session could not be created.").to_json
      end

      # Store request in database
      request = Request.new
      request.session_id = session_id
      request.token = token
      request.blind_name = name
      request.answered = false
      request.save!
      
      # Create notification
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
      
      # Send notification
  		Urbanairship.push(notification)
    
      return request_to_hash(request).to_json
    end

    # Get a request
    get '/request/:short_id' do
      content_type 'application/json'

      request = Request.first(:short_id => params[:short_id])
      if request
        return request_to_hash(request).to_json
      else
        halt 404,
        {'Content-Type' => 'application/json'},
        create_error_hash(ERROR_REQUEST_NOT_FOUND, "Request not found").to_json
      end
    end
    
    # Get a request
    put '/request/:short_id/answer' do
      content_type 'application/json'
      
      # Get name from body
      begin
        body_params = JSON.parse(request.body.read)
        name = body_params["name"]
      rescue Exception => e
        name = NIL
      end

      request = Request.first(:short_id => params[:short_id])
      if request
        if request.answered?
          return create_error_hash(ERROR_REQUEST_ALREADY_ANSWERED, "The request has already been answered.").to_json
        else
          # Update request
          request.helper_name = name
          request.answered = true
          request.save!
      
          return request_to_hash(request).to_json
        end
      else
        halt 404,
        {'Content-Type' => 'application/json'},
        create_error_hash(ERROR_REQUEST_NOT_FOUND, "Request not found").to_json
      end
    end
    
    # Rate a request
    put '/request/:short_id/rate' do
      content_type 'application/json'
      
      # Get role and rating from body
      begin
        body_params = JSON.parse(request.body.read)
        role = body_params["role"]
        rating = body_params["rating"]
      rescue Exception => e
        Log.info e.message
        return create_error_hash(ERROR_INVALID_BODY, "The body is not valid. This could mean that one or more paramters are missing.").to_json
      end
  
      request = Request.first(:short_id => params[:short_id])
      if request
        if request.answered?
          
          if role == "blind"
            request.blind_rating = rating
            request.save!
          elsif role == "helper"
            request.helper_rating = rating
            request.save!
          else
            return create_error_hash(ERROR_UNDEFINED_ROLE, "The request has not been answered and can therefore not be rated.").to_json
          end
        else
          return create_error_hash(ERROR_REQUEST_NOT_ANSWERED, "The request has not been answered and can therefore not be rated.").to_json
        end
      else
        return create_error_hash(ERROR_REQUEST_NOT_FOUND, "Request not found.").to_json
      end
    end
  end
  
  # Convert a request to JSON
  def request_to_hash(request)
    return { "opentok" => {
               "session_id" => request.session_id,
               "token" => request.token
             },
             "short_id" => request.short_id,
             "blind_name" => request.blind_name,
             "helper_name" => request.helper_name,
             "answered" => request.answered
           }
  end
  
  # Create error
  def create_error_hash(code, message)
    return { "error" => {
               "code" => code,
               "message" => message
             }
           }
  end
end