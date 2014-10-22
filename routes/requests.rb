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

    # Create new request
    post '/?' do
      begin
        token_repr = body_params["token"]
        TheLogger.log.info("request post, token " + token_repr )
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      token = token_from_representation(token_repr)
      user = token.user

      begin
        session = OpenTokSDK.create_session :media_mode => :relayed
        session_id = session.session_id
        token = OpenTokSDK.generate_token session_id
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


      requests_helper.check_requests 1

      EventBus.announce(:request_created, request_id: request.id)
      return request.to_json
    end

    # Get a request
    get '/:short_id' do
      TheLogger.log.info("get request, shortId:  " + params[:short_id] )
      return request_from_short_id(params[:short_id]).to_json
    end

    # Answer a request
    put '/:short_id/answer' do
      begin
        token_repr = body_params["token"]

        TheLogger.log.info("answer request, token  " + token_repr )
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      helper = helper_from_token token_repr 
      request = request_from_short_id(params[:short_id])

      if request.answered?
        EventBus.announce(:try_answer_request_but_already_answered, request_id: request.id, helper:helper)
        give_error(400, ERROR_REQUEST_ALREADY_ANSWERED, "The request has already been answered.").to_json
      elsif request.stopped?
        EventBus.announce(:try_answer_request_but_already_stopped, request_id: request.id, helper:helper)
        give_error(400, ERROR_REQUEST_STOPPED, "The request has been stopped.").to_json
      else
        EventBus.announce(:request_answered, request_id: request.id, helper:helper)

        return request.to_json
      end
    end

    # A helper can cancel his own answer. This should only be done if the session has not already started.
    put '/:short_id/answer/cancel' do
      begin
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
      token = token_from_representation(token_repr)
      user = token.user
      request = request_from_short_id(params[:short_id])

      if request.helper.nil?
        give_error(400, ERROR_USER_NOT_FOUND, "No helper attached to request - it cant be cancelled").to_json
      end
      if request.stopped?
        give_error(400, ERROR_REQUEST_STOPPED, "The request has been stopped.").to_json
      elsif request.helper._id != user._id
        give_error(400, ERROR_NOT_PERMITTED, "This action is not permitted for the user.").to_json
      end

      EventBus.announce(:request_cancelled, request_id: request.id, helper_id: user.id)

      return request.to_json
    end

    # The blind or a helper can disconnect from a started session thereby stopping the session.
    put '/:short_id/disconnect' do
      begin
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      token = token_from_representation(token_repr)
      user = token.user
      request = request_from_short_id(params[:short_id])

      if request.stopped?
        give_error(400, ERROR_REQUEST_STOPPED, "The request has been stopped.").to_json
      elsif request.blind._id != user._id && request.helper._id != user._id
        give_error(400, ERROR_NOT_PERMITTED, "This action is not permitted for the user.").to_json
      end

      EventBus.announce(:request_stopped, request_id: request.id)

      return request.to_json
    end

    # Rate a request
    put '/:short_id/rate' do
      begin
        rating = body_params["rating"]
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      token = token_from_representation(token_repr)
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

  def requests_helper
    ua_config = settings.config['urbanairship']
    RequestsHelper.new ua_config, TheLogger
  end

  # Find a request from a short ID
  def request_from_short_id(short_id)
    request = Request.first(:short_id => short_id)
    if request.nil?
      give_error(400, ERROR_REQUEST_NOT_FOUND, "Request not found.").to_json
    end

    return request
  end
end
