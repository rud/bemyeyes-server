class App < Sinatra::Base
  register Sinatra::Namespace

  namespace '/auth' do
    post '/reset-password' do
      begin
        body_params = JSON.parse(request.body.read)
        email = body_params["email"]
        user = User.first({:email => email})
        token = ResetPasswordToken.create
        token.user = user
        token.save!
        user.save!
        rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "Unable to create reset password token" + e.message).to_json
      end
    end
  end
end
