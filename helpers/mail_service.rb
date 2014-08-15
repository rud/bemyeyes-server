require 'mandrill'

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
