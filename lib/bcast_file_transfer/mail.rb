module BcastFileTransfer
  class Mail
    def self.send_mail(config_hash, script_result)
      generate_email_body(script_result)
    end

    def self.generate_email_body(script_result)
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
      puts "ERB:\n\n #{email_text}"
    end
  end
end
