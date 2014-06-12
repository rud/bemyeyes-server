class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin devices namespace
  namespace '/reset-password' do
    get '/' do
      reset_password_token = params["reset_password_token"]
      @token = ResetPasswordToken.first({:token => reset_password_token})
      if @token.nil?
        @error = "User not found"
      end
      erb :reset_password
    end

    post '/' do
      token = params[:token]
      token = ResetPasswordToken.first({:token => token})
      if token.nil?
        @error = "User not found"
        return
      end

      input_password = params['inputPassword']
      token.user.password = input_password
      token.delete

      @success = "Password Changed!"
      erb :password_changed
    end
  end
end
