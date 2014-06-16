require_relative '../helpers/reset_password'

class App < Sinatra::Base
  register Sinatra::Namespace

  # Begin devices namespace
  namespace '/reset-password' do
    get '/' do
      reset_password_token = params["reset_password_token"]
      @token = ResetPasswordToken.first({:token => reset_password_token})
      if @token.nil?
        @error = "You have already reset your password. <br/>If you want to reset your password again go to the app and request another password reset"
      end
      erb :reset_password
    end

    post '/' do
      reset_password_service = ResetPasswordService.new TheLogger
      token = params[:token]
      input_password = params[:inputPassword]
      success, message = reset_password_service.reset_password token, input_password

      if success
        @success = message
      else
        @error = message
      end

      erb :password_changed
    end
  end
end
