# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
main_domain = case Rails.env.to_sym
when :development
  'http://localhost:3000'
when :test
  'http://localhost:33000'
else
  'https://*.datadryad.org'
end
Rails.application.config.content_security_policy_report_only = true
Rails.application.config.content_security_policy do |policy|
  # policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.include?('dev') # ??????
  policy.connect_src :self,
                     'https://blog.datadryad.org',
                     'https://*.google-analytics.com',
                     'https://cdn.jsdelivr.net',
                     'https://*.awswaf.com',
                     'https://*.datacite.org',
                     'https://*.amazonaws.com',
                     main_domain
  policy.style_src :self, :strict_dynamic, main_domain
  policy.style_src_attr :self, :unsafe_inline, main_domain
  policy.style_src_elem :unsafe_inline,
                        'https://*.googleapis.com',
                        main_domain
  policy.font_src :self,
                  'https://fonts.gstatic.com',
                  main_domain

  policy.img_src :self, :https, :data
  policy.object_src :none
  policy.script_src :self, :unsafe_eval, main_domain
  policy.script_src_attr :self, :unsafe_inline, main_domain
  policy.script_src_elem :self,
                         :unsafe_inline,
                         'https://www.googletagmanager.com',
                         'https://*.google-analytics.com',
                         'https://*.awswaf.com',
                         'https://cdn.jsdelivr.net',
                         'https://cdnjs.cloudflare.com',
                         'https://js.stripe.com',
                         main_domain
  policy.worker_src :self,
                    :blob,
                    'https://cdnjs.cloudflare.com',
                    main_domain
  policy.child_src :blob

  #   # If you are using webpack-dev-server then specify webpack-dev-server host
  #   policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?

  # Specify URI for violation reports
  policy.report_uri "/csp-violation-report-endpoint"
  policy.default_src :self, main_domain
  policy.frame_src '*'
  # policy.frame_ancestors :none
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
