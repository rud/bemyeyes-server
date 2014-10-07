class App < Sinatra::Base
def helper_from_token token_repr
    token = token_from_representation(token_repr)
    user = token.user

    helper = Helper.first(:_id => user._id)
    helper
  end


  # Find token by representation of the token
  def token_from_representation(repr)
    token = Token.first(:token => repr)
    if token.nil?
      give_error(400, ERROR_USER_TOKEN_NOT_FOUND, "Token not found.").to_json
    end

    if !token.valid?
      give_error(400, ERROR_USER_TOKEN_EXPIRED, "Token has expired.").to_json
    end

    return token
  end

   def helper_from_id(user_id)
    model_from_id(user_id, Helper, ERROR_USER_NOT_FOUND, "No helper found.")
  end

  def user_from_id(user_id)
    model_from_id(user_id, User, ERROR_USER_NOT_FOUND, "No user found.")
  end

  def model_from_id(id, model_class, code, message)
    model = model_class.first(:_id => id)
    if model.nil?
      give_error(400, code, message).to_json
    end
    
    return model
  end
end
