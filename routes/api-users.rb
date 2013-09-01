class App < Sinatra::Base
  register Sinatra::Namespace

  namespace '/api' do
    before do
      protected!
    end

    namespace '/users' do
    
      # Create new user
      post '/?' do
        content_type 'application/json'
      
        begin
          body_params = JSON.parse(request.body.read)
          username = body_params["username"]
          secure_password = body_params["password"]
          email = body_params["email"]
          first_name = body_params["first_name"]
          last_name = body_params["last_name"]
          role = body_params["role"]
        rescue Exception => e
          return create_error_hash(ERROR_INVALID_BODY, "The body is not valid. This could mean that one or more paramters are missing.").to_json
        end
        
        # Check if role is supported
        if role != "blind" && role != "helper"
          return create_error_hash(ERROR_UNDEFINED_ROLE, "Undefined role.").to_json
        end
        
        # Check if username is taken
        existing_user = User.first(:username => username)
        if !existing_user.nil?
          return create_error_hash(ERROR_USER_USERNAME_TAKEN, "The username is taken.").to_json
        end
        
        # Check if e-mail is already registered
        existing_user = User.first(:email => email)
        if !existing_user.nil?
          return create_error_hash(ERROR_USER_EMAIL_ALREADY_REGISTERED, "The e-mail is already registered.").to_json
        end
        
        begin
          password = AESCrypt.decrypt(secure_password, settings.config["security_salt"])
        rescue Exception => e
          return create_error_hash(ERROR_INVALID_PASSWORD, "The password is invalid.").to_json
        end
        
        user = User.create
        user.username = username
        user.password = password
        user.email = email
        user.first_name = first_name
        user.last_name = last_name
        user.role = role
        user.save!
        
        user = User.first(:id2 => user.id2)
        if user.nil?
          return create_error_hash(ERROR_USER_NOT_FOUND, "No user found.").to_json
        end
  
        return user
      end
      
      # Get user by id
      get '/:user_id' do
        content_type 'application/json'
        
        user = User.first(:id2 => user.id2)
        if user.nil?
          return create_error_hash(ERROR_USER_NOT_FOUND, "No user found.").to_json
        end
  
        return user
      end
      
      # Login
      post '/login' do
        content_type 'application/json'
      
        begin
          body_params = JSON.parse(request.body.read)
          secure_password = body_params["password"]
        rescue Exception => e
          return create_error_hash(ERROR_INVALID_BODY, "The body is not valid. This could mean that one or more paramters are missing.").to_json
        end
        
        # We need either a username or an e-mail to login
        if body_params['username'].nil? && body_params['email'].nil?
          return create_error_hash(ERROR_INVALID_BODY, "Missing username or e-mail.").to_json
        end
        
        begin
          password = AESCrypt.decrypt(secure_password, settings.config["security_salt"])
        rescue Exception => e
          return create_error_hash(ERROR_INVALID_PASSWORD, "The password is invalid.").to_json
        end
        
        if !body_params['username'].nil? # Login using username
          user = User.authenticate_using_username(body_params['username'], password)
        elsif !body_params['email'].nil? # Login using e-mail
          user = User.authenticate_using_email(body_params['email'], password)
        end
        
        if user.nil?
          return create_error_hash(ERROR_USER_INCORRECT_CREDENTIALS, "No user found.").to_json
        end
        
        token = Token.create
        user.tokens.push(token)
        user.save!
        
        return token.to_json
      end
      
      # Authenticate token
      put '/authenticate' do
        content_type 'application/json'
      
        begin
          body_params = JSON.parse(request.body.read)
          token_repr = body_params["token"]
        rescue Exception => e
          return create_error_hash(ERROR_INVALID_BODY, "The body is not valid. This could mean that one or more paramters are missing.").to_json
        end
        
        token = Token.first(:token => token_repr)
        if token.nil?
          return create_error_hash(ERROR_USER_TOKEN_NOT_FOUND, "Token not found.").to_json
        end
        
        if !token.valid?
          return create_error_hash(ERROR_USER_TOKEN_EXPIRED, "Token has expired.").to_json
        end

        return { "valid" => true, "expiry_date" => token.expiry_date, "user_id" => token.user.id2 }.to_json
      end
      
    end # End namespace /user
  end # End namespace /api

end