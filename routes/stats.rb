class App < Sinatra::Base
  register Sinatra::Namespace
  namespace '/stats' do
    get '/community' do
    
      return { 'blind' => Blind.count, 'helpers' => Helper.count, 'no_helped' =>Request.count }.to_json
    end

    get '/profile/:token_repr' do
       token_repr = params[:token_repr]
      token = token_from_representation(token_repr)
      if !token.valid?
        give_error(400, ERROR_USER_TOKEN_EXPIRED, "Token has expired.").to_json
      end
      return {'no_helped' => 42}.to_json
    end
  end

   # Find token by representation of the token
  def token_from_representation(repr)
    token = Token.first(:token => repr)
    if token.nil?
      give_error(400, ERROR_USER_TOKEN_NOT_FOUND, "Token not found.").to_json
    end
    
    return token
  end
end
