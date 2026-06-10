# :nocov:
namespace :internal do

  desc 'Send daily email with CSP violation reports details'
  task csp_reports: :environment do
    StashEngine::NotificationsMailer.csp_violations.deliver_now
  end
end
# :nocov:
