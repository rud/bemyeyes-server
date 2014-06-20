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

  def create_mail_service settings
    mandrill_config = settings.config['mandrill']
    MailService.new mandrill_config
  end

  namespace '/auth' do
    post '/request-reset-password' do
      begin
        body_params = JSON.parse(request.body.read)
        email = body_params["email"]
        user = User.first({:email => email})

         if user.nil?
          give_error(400, ERROR_USER_NOT_FOUND, "User Not found")
        end
        
        if user.is_external_user
          give_error(400, ERROR_NOT_PERMITTED, "external users can not have their passwords reset")
        end

        token = create_reset_password_token user 
        mail_service = create_mail_service settings
        
        reset_password_mail_message = ResetPasswordMailMessage.new(request.base_url, token.token, user.email, "#{user.first_name} #{user.last_name}")
        mail_service.send_mail reset_password_mail_message
      rescue Exception => e
        give_error(400, ERROR_INVALID_BODY, "Unable to create reset password token " + e.message).to_json
      end
    end
  end
end
