require 'delayed_job_active_record'
# see https://axiomq.com/blog/deal-with-long-running-rails-tasks-with-delayed-job/

Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 2
Delayed::Worker.max_run_time = 6.hours
# Was going to change, but looks like read ahead is ignored for MySQL and if using priority, anyway.
# https://stackoverflow.com/questions/35734246/how-does-priority-interact-with-read-ahead-in-delayed-job
Delayed::Worker.read_ahead = 5
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

# when there are jobs in the software and supplemental queues, give them priority, apparently lower numbers are higher priority
# See https://github.com/collectiveidea/delayed_job/tree/v4.1.9
Delayed::Worker.queue_attributes = {
  zenodo_software: { priority: -10 },
  zenodo_supp: { priority: -10 },
  zenodo_copy: { priority: 10 }
}
