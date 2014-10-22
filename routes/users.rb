class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin users namespace
  namespace '/users' do

    before do
      next unless request.post? || request.put?
      @body_params = JSON.parse(request.body.read)
    end

    def body_params
      @body_params
    end

    def validate_body_for_create_user
      begin
        required_fields = {"required" => ["email", "first_name", "last_name", "role"]}
        schema = User::SCHEMA.merge(required_fields)
        JSON::Validator.validate!(schema, body_params)
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
    end

    # Create new user
    post '/?' do
      validate_body_for_create_user
      user = case body_params["role"].downcase
      when "blind"
        Blind.new
      when "helper"
        Helper.new
      else
        give_error(400, ERROR_UNDEFINED_ROLE, "Undefined role.").to_json
      end
      if !body_params['password'].nil?
        password = decrypted_password(body_params['password'])
        user.update_attributes body_params.merge({ "password" => password })
      elsif !body_params['user_id'].nil?
        user.update_attributes body_params.merge({ "user_id" => body_params['user_id'] })
        user.is_external_user = true
      else
        give_error(400, ERROR_INVALID_BODY, "Missing parameter 'user_id' for registering a Facebook user or parameter 'password' for registering a regular user.").to_json
      end
      begin
        user.save!
      rescue Exception => e
        give_error(400, ERROR_USER_EMAIL_ALREADY_REGISTERED, "The e-mail is already registered.").to_json if e.message.match /email/i
      end
      EventBus.announce(:user_created, user_id: user.id)
      return user_from_id(user._id).to_json
    end

    # Logout, thereby deleting the token
    put '/logout' do
      begin
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      token = token_from_representation(token_repr)
      if !token.valid?
        give_error(400, ERROR_USER_TOKEN_EXPIRED, "Token has expired.").to_json
      end
      begin
        device = token.device
        token.delete
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, e.message)
      end

      EventBus.publish(:user_logged_out, device_id:device.id) unless device.nil?
      return { "success" => true }.to_json
    end

    def get_device
      device_token = body_params["device_token"]
      if device_token.nil? or device_token.length == 0
        raise "device_token must be present"
      end

      device = Device.first(:device_token => device_token)
      if device.nil?
        raise "device not found"
      end
      device
    end
    # Login, thereby creating an new token
    post '/login' do
      begin
        device = get_device
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "#{e.message}. device_token:
          #{body_params["device_token"]}").to_json
      end

      secure_password = body_params["password"]
      user_id = body_params["user_id"]

      # We need either a password or a user ID to login
      if secure_password.nil? && user_id.nil?
        give_error(400, ERROR_INVALID_BODY, "Missing password or user ID.").to_json
      end

      # We need an e-mail to login
      if body_params['email'].nil?
        give_error(400, ERROR_INVALID_BODY, "Missing e-mail.").to_json
      end

      if !secure_password.nil?
        # Login using e-mail and password
        password = decrypted_password(secure_password)
        user = User.authenticate_using_email(body_params['email'], password)

        # Check if we managed to log in
        if user.nil?
          give_error(400, ERROR_USER_INCORRECT_CREDENTIALS, "No user found matching the credentials.").to_json
        end
      elsif !user_id.nil?
        # Login using user ID
        user = User.authenticate_using_user_id(body_params['email'], body_params['user_id'])

        # Check if we managed to log in
        if user.nil?
          give_error(400, ERROR_USER_FACEBOOK_USER_NOT_FOUND, "The Facebook user was not found.").to_json
        end
      end

      # We did log in, create token
      token = Token.new
      token.valid_time = 365.days
      user.tokens.push(token)
      user.devices.push(device)

      device.token = token
      token.device = device
      device.save!
      token.save!

      EventBus.publish(:user_logged_in, device_id:device.id)
     
      return { "token" => JSON.parse(token.to_json), "user" => JSON.parse(token.user.to_json) }.to_json
    end

    # Login with a token
    put '/login/token' do
      begin
        token_repr = body_params["token"]
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end

      token = token_from_representation(token_repr)
      if !token.valid?
        give_error(400, ERROR_USER_TOKEN_EXPIRED, "Token has expired.").to_json
      end

      return { "user" => JSON.parse(token.user.to_json) }.to_json
    end

    # Get user by id
    get '/:user_id' do
      content_type 'application/json'

      return user_from_id(params[:user_id]).to_json
    end

    #days param
    get '/helper_points/:user_id' do
      days = params[:days]|| 30
      helper = helper_from_id(params[:user_id])

      days = days.to_i

      sums = HelperPointDateHelper.get_aggregated_points_for_each_day(helper, days)

      return sums.to_json
    end

    get '/helper_points_sum/:user_id' do
      retval = OpenStruct.new
      helper = helper_from_id(params[:user_id])
      if(helper.helper_points.count == 0)
        retval.sum = 0
        return retval.marshal_dump.to_json
      end
      retval.sum = helper.helper_points.inject(0){|sum,x| sum + x.point }
      return retval.marshal_dump.to_json
    end

    # Update a user
    put '/:user_id' do
      user = user_from_id(params[:user_id])
      begin
        JSON::Validator.validate!(User::SCHEMA, body_params)
        user.update_attributes!(body_params)
      rescue Exception => e
        puts e.message
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
      EventBus.announce(:user_updated, user: user)
      return user
    end

    def is_24_hour_string the_str
      !the_str.nil? and /\d\d:\d\d/.match the_str
    end

    put '/info/:token_repr' do
      begin
        token = token_from_representation(params[:token_repr])
        user = token.user
        user.wake_up = body_params['wake_up'] if is_24_hour_string body_params['wake_up']
        user.go_to_sleep = body_params['go_to_sleep'] if is_24_hour_string body_params['go_to_sleep']
        user.utc_offset = body_params['utc_offset'] unless body_params['utc_offset'].nil? or not /-?\d{1,2}/.match body_params['utc_offset']

        user.save!
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "The body is not valid.").to_json
      end
    end

    put '/:user_id/snooze/:period' do
      puts params[:period]
      raise Sinatra::NotFound unless params[:period].match /^(1h|3h|1d|3d|1w|stop)$/
      user = user_from_id(params[:user_id])
      #Stores it in UTC, perhaps change it using timezone info later on.
      current_time = Time.now.utc
      #TODO refactor this case...
      new_time = case params[:period]
        when '1h'
          current_time + 1.hour
        when '3h'
          current_time + 3.hour
        when '1d'
          current_time + 1.day
        when '3d'
          current_time + 3.day
        when '1w'
          current_time + 1.week
        when 'stop'
          current_time
      end
      user.update_attributes!({:snooze_period => params[:period], :available_from => new_time})
      return user.to_json
    end
  end # End namespace /users
  
  # Decrypt the password
  def decrypted_password(secure_password)
    begin
      return AESCrypt.decrypt(secure_password, settings.config["security_salt"])
    rescue Exception => e
      give_error(400, ERROR_INVALID_PASSWORD, "The password is invalid.").to_json
    end
  end

end
