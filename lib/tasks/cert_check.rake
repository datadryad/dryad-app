# :nocov:
namespace :certbot do
  desc 'Check SSL certificate expiration and send email if near expiration'
  task check_and_notify: :environment do
    threshold = 15
    now = Time.now.to_i

    output = `sudo certbot certificates`
    blocks = output.split("\n\n")

    blocks.each do |block|
      next unless block.include?('Certificate Name:')

      domain_line = block.lines.find { |l| l.include?('Domains:') }
      expiry_line = block.lines.find { |l| l.include?('Expiry Date:') }

      next unless domain_line && expiry_line

      domains = domain_line.split(':')[1].strip
      expiry_str = expiry_line.match(/Expiry Date:\s+(.*?)\s+\(VALID:/)[1]
      expiry_ts = Time.parse(expiry_str).to_i

      days_left = (expiry_ts - now) / 86_400

      if days_left <= threshold
        puts "[WARNING] #{domains} expires in #{days_left} days (#{expiry_str})"
        StashEngine::NotificationsMailer.certbot_expiration(days_left).deliver_now

        sns = Aws::SNS::Client.new(
          region: APP_CONFIG[:s3][:region],
          access_key_id: APP_CONFIG[:s3][:key],
          secret_access_key: APP_CONFIG[:s3][:secret]
        )

        sns.publish({
                      topic_arn: APP_CONFIG[:s3][:sns_arn],
                      subject: "🚨 Shibboleth SSL Cert expires in #{days_left} days!",
                      message: "Certificate for #{Rails.env} server #{domains} expires in #{days_left} days."
                    })
        puts 'SNS alert sent'
      else
        puts "[OK] #{domains} valid for #{days_left} more days"
      end
    end
  end
end
# :nocov:
