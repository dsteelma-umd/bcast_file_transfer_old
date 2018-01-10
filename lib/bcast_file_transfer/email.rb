module BcastFileTransfer
  class Email
    require 'mail'

    def self.send_mail(config_hash, script_result)
      smtp_config = config_hash['smtp_server']
      mail_config = config_hash['mail']

      mail_from = mail_config['from']
      mail_to = mail_config['to']
      mail_subject = generate_subject(config_hash, script_result)
      mail_body = generate_email_body(config_hash, script_result)

      mail = Mail.new do
        from    mail_from.to_s
        to      mail_to.to_s
        subject mail_subject.to_s
        body    mail_body.to_s
      end

      smtp_debug = smtp_config['debug']

      if smtp_debug
        mail.delivery_method :logger
      else
        smtp_address = smtp_config['address']
        smtp_port = smtp_config['port']
        mail.delivery_method :smtp, address: smtp_address, port: smtp_port
      end

      mail.deliver!
    end

    def self.generate_subject(config_hash, script_result)
      if script_result.success?
        "#{config_hash['job_name']} File transfer OK"
      else
        "#{config_hash['job_name']} File transfer FAILED"
      end
    end

    def self.generate_email_body(config_hash, script_result)
      email_template_filename = if script_result.success?
                                  '../../resources/mail_templates/success.erb'
                                else
                                  '../../resources/mail_templates/failure.erb'
                                end

      email = File.read(File.join(File.dirname(File.expand_path(__FILE__)), email_template_filename))

      email_text = ERB.new(email, 0, '>').result(binding)
      email_text
    end
  end
end
