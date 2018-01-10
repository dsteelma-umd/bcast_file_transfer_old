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
        from    "#{mail_from}"
        to      "#{mail_to}"
        subject "#{mail_subject}"
        body    "#{mail_body}"
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
      mail_config = config_hash['mail']
      if script_result.success?
        "#{mail_config['job_name']} File transfer OK"
      else
        "#{mail_config['job_name']} File transfer FAILED"
      end
    end

    def self.generate_email_body(config_hash, script_result)
      email = ''

      if script_result.success?
        email = File.read(
          File.join(File.dirname(File.expand_path(__FILE__)), '../../resources/mail_templates/success.erb')
        )
      else
        email = File.read(
          File.join(File.dirname(File.expand_path(__FILE__)), '../../resources/mail_templates/failure.erb')
        )
      end

      email_text = ERB.new(email, 0, '>').result(binding)
      email_text
    end
  end
end
