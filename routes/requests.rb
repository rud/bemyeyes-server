require_relative '../helpers/requests_helper'
class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin requests namespace
  namespace '/requests' do

  before do
    next unless request.post? || request.put?
      @body_params = JSON.parse(request.body.read)
  end

  def body_params
    @body_params
  end

  def token_repr
    begin
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
      token_repr
  end

  def rating
     begin
        rating = body_params["rating"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
    rating
  end

  def token
    token_from_representation_with_validation(token_repr, true)
  end

  def user
    token.user
  end


    # Create new request
    post '/?' do
      begin
        session = OpenTokSDK.create_session :media_mode => :relayed
        session_id = session.session_id
        open_tok_token = OpenTokSDK.generate_token session_id
      rescue Exception => e
        give_error(500, ERROR_REQUEST_SESSION_NOT_CREATED, "The session could not be created.")
      end

      # Store request in database
      request = Request.create
      request.short_id_salt = settings.config["short_id_salt"]
      request.session_id = session_id
      request.token = open_tok_token
      request.blind = user
      request.answered = false
      request.save!

      ua_config = settings.config['urbanairship']
      @requests_helper = RequestsHelper.new ua_config, TheLogger
      @requests_helper.check_requests 10
      return request.to_json
    end

    # Get a request
    get '/:short_id' do
        TheLogger.log.info("get request, shortId:  " + params[:short_id] )
      return request_from_short_id(params[:short_id]).to_json
    end

    # Answer a request
    put '/:short_id/answer' do
      request = request_from_short_id(params[:short_id])

      if request.answered?
        request.helper = user
        point = HelperPoint.answer_push_message
        request.helper.helper_points.push point
        request.helper.save
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
      request = request_from_short_id(params[:short_id])

      if request.stopped?
        give_error(400, ERROR_EQUEST_STOPPED, "The request has been stopped.").to_json
      elsif request.helper._id != user._id
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
      request = request_from_short_id(params[:short_id])

      if request.stopped?
        give_error(400, ERROR_EQUEST_STOPPED, "The request has been stopped.").to_json
      elsif request.blind._id != user._id && request.helper._id != user._id
        give_error(400, ERROR_NOT_PERMITTED, "This action is not permitted for the user.").to_json
      end

      # Update request
      request.stopped = true
      request.save!

      #update helper with points for call
      if !request.helper.nil?
        point = HelperPoint.finish_helping_request
        request.helper.helper_points.push point
        request.helper.save
      end

      return request.to_json
    end

    # Rate a request
    put '/:short_id/rate' do
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
