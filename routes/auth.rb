require_relative '../helpers/mail_service'
require_relative '../helpers/mail_messages/reset_password_mail_message'
class App < Sinatra::Base
  register Sinatra::Namespace
  def create_reset_password_token user
    token = ResetPasswordToken.create
    token.user = user
    token.save!
    user.save!
    token
  end

  def user
    @user ||= User.first({:email => @email}) || give_error(400, ERROR_USER_NOT_FOUND, "User Not found")
  end

  namespace '/auth' do
    post '/request-reset-password' do
      begin
        body_params = JSON.parse(request.body.read)
        @email = body_params["email"]

        if user.is_external_user
          give_error(400, ERROR_NOT_PERMITTED, "external users can not have their passwords reset")
        end

        token = create_reset_password_token user

        EventBus.publish(:rest_password_token_created, token_id: token.id)

      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "Unable to create reset password token").to_json
      end
    end
  end
end
