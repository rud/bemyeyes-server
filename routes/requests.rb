class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin requests namespace
  namespace '/requests' do
  
    # Create new request
    post '/?' do
      content_type 'application/json'
      
      begin
        body_params = JSON.parse(request.body.read)
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      token = token_from_representation_with_validation(token_repr, true)
      user = token.user

      begin
        session_properties = { OpenTok::SessionPropertyConstants::P2P_PREFERENCE => "enabled" }
        session_id = OpenTokSDK.create_session(NIL, session_properties)
        token = OpenTokSDK.generateToken :session_id => session_id
      rescue Exception => e
        give_error(500, ERROR_REQUEST_SESSION_NOT_CREATED, "The session could not be created.")
      end

      # Store request in database
      request = Request.create
      request.short_id_salt = settings.config["short_id_salt"]
      request.session_id = session_id
      request.token = token
      request.blind = user
      request.answered = false
      request.save!
      #TODO set all this in helper method since it's reused in the cronjob...
      # Find helpers
      helpers = Helper.available(request, 5)
      
      # Find device tokens
      tokens = helpers.collect { |u| u.devices.collect { |d| d.device_token } }.flatten
      
      # Create notification
      name = user.first_name + " " + user.last_name
      notification_args_name = name
      notification = {
        :device_tokens => tokens,
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
    
      return request.to_json
    end

    # Get a request
    get '/:short_id' do
      content_type 'application/json'

      return request_from_short_id(params[:short_id]).to_json
    end
    
    # Answer a request
    put '/:short_id/answer' do
      content_type 'application/json'
      
      begin
        body_params = JSON.parse(request.body.read)
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      token = token_from_representation_with_validation(token_repr, true)
      user = token.user
      request = request_from_short_id(params[:short_id])
      
      if request.answered?
        give_error(400, ERROR_REQUEST_ALREADY_ANSWERED, "The request has already been answered.").to_json
      elsif request.stopped?
        give_error(400, ERROR_REQUEST_STOPPED, "The request has been stopped.").to_json
      else
        # Update request
        request.helper = user
        request.answered = true
        request.save!
    
        return request.to_json
      end
    end
    
    # A helper can cancel his own answer. This should only be done if the session has not already started.
    put '/:short_id/answer/cancel' do
      content_type 'application/json'
      
      begin
        body_params = JSON.parse(request.body.read)
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
      
      token = token_from_representation_with_validation(token_repr, true)
      user = token.user
      request = request_from_short_id(params[:short_id])
      
      if request.stopped?
        give_error(400, ERROR_EQUEST_STOPPED, "The request has been stopped.").to_json
      elsif request.helper.id2 != user.id2
        give_error(400, ERROR_NOT_PERMITTED, "This action is not permitted for the user.").to_json
      end
      
      # Update request
      request.helper = nil
      request.answered = false
      request.save!
      
      return request.to_json
    end
    
    # The blind or a helper can disconnect from a started session thereby stopping the session.
    put '/:short_id/disconnect' do
      content_type 'application/json'
      
      begin
        body_params = JSON.parse(request.body.read)
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
      
      token = token_from_representation_with_validation(token_repr, true)
      user = token.user
      request = request_from_short_id(params[:short_id])
      
      if request.stopped?
        give_error(400, ERROR_EQUEST_STOPPED, "The request has been stopped.").to_json
      elsif request.blind.id2 != user.id2 && request.helper.id2 != user.id2
        give_error(400, ERROR_NOT_PERMITTED, "This action is not permitted for the user.").to_json
      end
      
      # Update request
      request.stopped = true
      request.save!
      
      return request.to_json
    end
    
    # Rate a request
    put '/:short_id/rate' do
      content_type 'application/json'
      
      begin
        body_params = JSON.parse(request.body.read)
        rating = body_params["rating"]
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
  
      token = token_from_representation_with_validation(token_repr, true)
      user = token.user
      request = request_from_short_id(params[:short_id])
      
      if request.answered?
        if user.role == "blind"
          request.blind_rating = rating
          request.save!
        elsif user.role == "helper"
          request.helper_rating = rating
          request.save!
        end
      else
        give_error(400, ERROR_REQUEST_NOT_ANSWERED, "The request has not been answered and can therefore not be rated.").to_json
      end
    end
    
  end # End namespace /request
  
  # Find a request from a short ID
  def request_from_short_id(short_id)
    request = Request.first(:short_id => short_id)
    if request.nil?
      give_error(400, ERROR_REQUEST_NOT_FOUND, "Request not found.").to_json
    end
    
    return request
  end
  
  # Find token by representation of the token
  def token_from_representation_with_validation(repr, validation)
    token = Token.first(:token => repr)
    if token.nil?
      give_error(400, ERROR_USER_TOKEN_NOT_FOUND, "Token not found.").to_json
    end
    
    if validation && !token.valid?
      give_error(400, ERROR_USER_TOKEN_EXPIRED, "Token has expired.").to_json
    end
    
    return token
  end

end