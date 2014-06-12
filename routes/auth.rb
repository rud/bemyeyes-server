require_relative '../helpers/mail_service'
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

        mandrill_config = settings.config['mandrill']
        mail_service = MailService.new mandrill_config
        reset_password_mail_message = ResetPasswordMailMessage.new(request.base_url, token.token, "klaus@hebsgaard.dk", "Klaus Hebsgaard")
        mail_service.send_mail reset_password_mail_message
        rescue Exception => e
          give_error(400, ERROR_INVALID_BODY, "Unable to create reset password token" + e.message).to_json
      end
    end
  end
end
