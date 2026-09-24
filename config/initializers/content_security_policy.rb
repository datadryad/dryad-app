# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
env_domain_mapping= {
  development: 'http://localhost:3000',
  test: 'http://localhost:33000',
  dev: 'https://*.datadryad.org',
  stage: 'https://*.datadryad.org',
  production: 'https://datadryad.org'
}
main_domain = env_domain_mapping[Rails.env.to_sym] || 'https://datadryad.org'

Rails.application.config.content_security_policy_report_only = true
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, main_domain

  # --------------------
  # CONNECT (XHR, fetch, websockets)
  # --------------------
  policy.connect_src :self,
                     :data,
                     'https://blog.datadryad.org',
                     'https://*.google-analytics.com',
                     'https://cdn.jsdelivr.net',
                     'https://*.awswaf.com',
                     'https://*.datacite.org',
                     'https://*.amazonaws.com',
                     'https://doi.org',
                     'https://doubleclick.net',
                     'http://localhost:3000',
                     'http://127.0.0.1:3000',
                     main_domain

  # --------------------
  # SCRIPTS
  # --------------------
  policy.script_src :self,
                    :unsafe_inline,
                    :unsafe_eval,
                    'https://www.googletagmanager.com',
                    'https://*.google-analytics.com',
                    'https://cdnjs.cloudflare.com',
                    'https://www.google.com',
                    'https://www.recaptcha.net',
                    'https://www.gstatic.com',
                    'https://*.awswaf.com',
                    'https://cdn.jsdelivr.net',
                    main_domain

  policy.script_src_elem :self,
                         :unsafe_inline,
                         :blob,
                         'https://www.googletagmanager.com',
                         'https://*.google-analytics.com',
                         'https://*.awswaf.com',
                         'https://*.proxy.hfzk.net.cn',
                         'https://cdn.jsdelivr.net',
                         'https://cdnjs.cloudflare.com',
                         'https://js.stripe.com',
                         'https://google.com',
                         'https://*.google.com',
                         'https://www.recaptcha.net',
                         'https://www.gstatic.com',
                         'https://www.gstatic.cn',
                         'https://*.googleapis.com',
                         'https://unpkg.com',
                         'https://altmetric.com',
                         'https://*.cloudfront.net',
                         'https://cdn.mathjax.org',
                         'https://doi.org',
                         'http://localhost:3000',
                         'http://127.0.0.1:3000',
                         main_domain

  policy.script_src_attr :unsafe_inline

  # --------------------
  # STYLES
  # --------------------
  policy.style_src :self,
                   :unsafe_inline,
                   'https://fonts.googleapis.com',
                   'https://*.googleapis.com',
                   'https://www.gstatic.com',
                   main_domain

  policy.style_src_elem :self,
                        :blob,
                        :data,
                        :unsafe_inline,
                        'https://*.googleapis.com',
                        'https://www.gstatic.com',
                        'https://altmetric.com',
                        main_domain

  policy.style_src_attr :unsafe_inline

  # --------------------
  # FONTS
  # --------------------
  policy.font_src :self,
                  :data,
                  'https://fonts.gstatic.com',
                  'https://fontsgstatic.cn',
                  'https://*.googleapis.com',
                  'chrome-extension:',
                  'moz-extension:',
                  'safari-web-extension:',
                  'https://*.proxy.hfzk.net.cn',
                  'https://cdn.scite.ai',
                  main_domain

  # --------------------
  # IMAGES
  # --------------------
  policy.img_src :self, :https, :data, :blob

  # --------------------
  # MEDIA
  # --------------------
  policy.media_src :self, :data, main_domain

  # --------------------
  # WORKERS / FRAMES
  # --------------------
  policy.worker_src :self, :blob, 'https://cdnjs.cloudflare.com', main_domain
  policy.child_src :blob
  policy.frame_src :self,
                   'https://www.google.com',
                   'https://www.recaptcha.net',
                   'https://js.stripe.com',
                   'https://hooks.stripe.com',
                   main_domain
  # policy.frame_ancestors :none

  # --------------------
  # SECURITY
  # --------------------
  policy.object_src :none
  # policy.require_trusted_types_for :script

  # --------------------
  # REPORTING
  # --------------------
  policy.report_uri "/csp-violation-report-endpoint"
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
