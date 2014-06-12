require_relative '../helpers/mail_service'

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
      @success = "Password Changed!"
      erb :password_changed
    end
  end
end
