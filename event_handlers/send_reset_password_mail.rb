class SendResetPasswordMail
  def initialize(settings)
    @settings = settings
  end

  def reset_password_token_created(payload)
    token_id = payload[:token_id]
    token = ResetPasswordToken.first(:_id => token_id)
    return if token.nil?
    user = token.user

    reset_password_mail_message = ResetPasswordMailMessage.new(AmbientRequest.instance.request.base_url, token.token, user.email, "#{user.first_name} #{user.last_name}")
    mail_service.send_mail reset_password_mail_message
  end

  private

  def mail_service
    mandrill_config = @settings.config['mandrill']
    MailService.new mandrill_config
  end
end
