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
#      puts mail.to_s
    end

    def self.generate_subject(config_hash, script_result)
      if script_result.success?
        'File transfer successful'
      else
        'File transfer failed'
      end
    end

    def self.generate_email_body(config_hash, script_result)
      #  comparison_results = script_result.comparison_results
      #  transfer_results = script_result.transfer_results

      #  (successful_transfers, failed_transfers) = transfer_results.partition(&:success?)

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
