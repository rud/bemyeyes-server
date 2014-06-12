require 'mandrill'
require_relative './thelogger_module'

class ResetPasswordMailMessage
  def initialize(base_url, token, receiver_email, receiver_name)
    @subject = "Be My Eyes - Change password"

    @html_body = "<h1>Forgot your password?</h1><p>Lets help you get a new one</p><p><a href='#{base_url}/reset-password/?reset_password_token=#{token}'>Reset your password</a></p>"
    @receiver_email = receiver_email
    @receiver_name = receiver_name
  end

  attr_accessor :receiver_name, :receiver_email, :subject, :html_body
end

class MailService 
  def initialize config
    @mandrill_api_key = config['api_key']
    @from_email = config['from_email']
    @from_name = config['from_name']
    @reply_to = config['reply_to']
  end

  def send_mail mail_message
      mandrill = Mandrill::API.new @mandrill_api_key
      message = {"html"=>mail_message.html_body,
       "subject"=>mail_message.subject,
       "from_email"=> @from_email,
       "from_name"=> @from_name,
       "to"=>
       [{"email"=>mail_message.receiver_email,
        "name"=>mail_message.receiver_name,
        "type"=>"to"}],
        "headers"=>{"Reply-To"=>@reply_to},
      }
      result = mandrill.messages.send message
      puts result
  end
end