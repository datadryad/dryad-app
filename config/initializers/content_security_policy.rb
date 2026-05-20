# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

common = %w[development test].include?(Rails.env.to_s) ? %w[http://localhost:3000] : %w[https://*.datadryad.org]

Rails.application.config.content_security_policy do |policy|
  # policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.include?('dev') # ??????
  policy.connect_src *%w[
    'self'
    https://blog.datadryad.org
    https://*.google-analytics.com
    https://cdn.jsdelivr.net/
    https://*.awswaf.com
    https://*.datacite.org
  ] + common
  policy.style_src *%w['self' 'strict-dynamic'] + common
  policy.style_src_attr *%w['self' 'unsafe-inline'] + common
  policy.style_src_elem *%w['unsafe-inline'] + common
  policy.font_src *%w['self'] + common
  policy.img_src :self, :https, :data
  policy.object_src :none
  policy.script_src *%w[self 'unsafe-eval' ] + common
  policy.script_src_elem *%w[
      'self'
      'unsafe-inline'
      https://www.googletagmanager.com
      https://*.google-analytics.com
      https://*.awswaf.com
      https://cdn.jsdelivr.net
      https://cdnjs.cloudflare.com
      https://js.stripe.com
    ] + common

  #   # If you are using webpack-dev-server then specify webpack-dev-server host
  #   policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?

  # Specify URI for violation reports
  policy.report_uri "/csp-violation-report-endpoint"
  policy.default_src *%w['self'] + common
  policy.frame_src *%w[*]
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
