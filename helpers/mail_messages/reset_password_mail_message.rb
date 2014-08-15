class ResetPasswordMailMessage
  def initialize(base_url, token, receiver_email, receiver_name)
    @subject = "Be My Eyes - Change password"

    @html_body = "<h1>Forgot your password?</h1><p>Lets help you get a new one</p><p><a href='#{base_url}/reset-password/?reset_password_token=#{token}'>Reset your password</a></p>"
    @receiver_email = receiver_email
    @receiver_name = receiver_name
  end

  attr_accessor :receiver_name, :receiver_email, :subject, :html_body
end
