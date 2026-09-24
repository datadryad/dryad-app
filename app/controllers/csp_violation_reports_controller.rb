class CspViolationReportsController < ApplicationController

  skip_forgery_protection

  # List of noisy third-party domain
  IGNORED_EXTENSIONS = [
    'doubao.com',                    # ByteDance's Doubao AI assistant tool (forces KaTeX layout styling) [3.2]
    'typekit.net',                   # Adobe Typekit font delivery system embedded in custom user layout frameworks
    'alicdn.com',                    # Alibaba CDN used for dynamic font loading and layout styling by e-commerce extension scripts
    'alipayobjects.com',             # Ant Group / Alipay CDN hosting script files for payment overlays or local shopping extensions
    'perplexity.ai',                 # Perplexity AI browser summary companion extension loading its native interface fonts
    'mindverse.ai',                  # Mindverse AI (German generative AI tool) sidebar/overlay browser helper extensions
    'file://',                       # Standard file protocol triggered when users open saved HTML page files locally
    'kaspersky-labs.com',            # Kaspersky Anti-Virus web protection utility injecting local traffic monitoring hooks
    'font.im',                       # Regional Chinese proxy mirroring Google Fonts frameworks locally
    'loli.net',                      # "Loli.net" public mirror used to cache Google Fonts (often bundled in local client layouts)
    'sevencdn.com',                  # SevenCDN network commonly mirroring public layouts or font frameworks
    'geekzu.org',                    # Geekzu public asset mirror frequently used to speed up font files across networks
    'stanford.edu',                  # Stanford University library proxy / ezproxy network links routing user traffic
    'edu.cn',                        # Chinese academic university reverse proxies (e.g., TJU, PKU) routing institutional access
    'netfree.link',                  # NetFree kosher content-filtering security software running on client ISP routers
    'androidplatform.net',           # System context indicator triggered by local Android in-app WebView wrappers
    'vvipquan.com',                  # Deceptive Chinese ad/tracker injection script running on an infected client machine
    'quanhu66.com',                  # Aggressive Chinese cookie-stuffing malware script executing in the client's workspace
    'lottingem.com',                 # Known browser redirect hijacker/adware extension injecting code scripts silently
    'infird.com',                    # Notorious malicious browser extension / Magecart skimmer attempting data theft
    'secured-pixel.com',             # External third-party marketing tracking framework or cookie tracker
    'qq.com',                        # Tencent QQ system scripts or local messaging helper extension hooks
    'scriptcdn.net',                 # Shared public asset CDN often used by smaller ad frameworks or web widgets
    'bing.com',                      # Microsoft Bing tracking components or browser search bar tool integrations
    'gtmpx.com',                     # Internal tracking framework component or analytics companion widget
    'basic-ntr.top',                 # Aggressive ad-delivery injection module or affiliate tracking pixel script
    'newmorehot.com',                # "Niumowang" (Bull Demon King) Cross-Border E-Commerce big data analysis tool
    'slant.co',                      # Slant product recommendation platform widgets or extension overlays
    'honey.io',                      # PayPal Honey browser coupon scanner injecting code to track cart totals
    'shopback.com',                  # ShopBack cashback extension injecting dynamic layout layers to track purchases
    'simplycodes.com',               # SimplyCodes discount companion extension scanning page state for coupons
    'merci-app.com',                 # Merci App (French grammar checker) injecting code to parse textbox fields
    'sharepointonline.com',          # Microsoft SharePoint corporate intranet layout elements running on a client browser
    'faceworks.nl',                  # Faceworks software optimization framework components or client-side utilities
    'opera-mini.net',                # Opera Mini browser system settings handling built-in data compression or ad-blocking layouts
    'xbase.cloud',                   # Cloud hosting component or dynamic client-side widget loader asset
    'hihonorcdn.com',                # Honor mobile device ecosystem built-in system browser optimization scripts
    '51.la',                         # "51.la" Chinese analytics script platform running on client extensions
    'baidu.com',                     # Baidu search engine widgets, translation helper scripts, or toolbar add-ons
    'youdao.com',                    # NetEase Youdao dictionary or automated web translation layout companions
    'lingosive.com',                 # Audio-based language learning toolbar or site summary tools
    'uc.cn',                         # UC Browser internal content recommendation or tracking pixel frames
    'bytegoofy.com',                 # Internal web utility package developed by ByteDance for telemetry handling
    'vinci.com',                     # Vinci concessions/energy group internal enterprise portal dependencies
    'bytednsdoc.com',                # ByteDance public document engine asset server or layout controller framework
    'zarinaccount.com',              # Regional financial integration component or localized banking/payment extension tool
    'bdstatic.com',                  # Baidu static asset server supplying baseline scripts for Chinese extensions
    'yiban.io',                      # Yiban educational or social networking web suite modules active on client systems
    'rsms.me',                       # Rasmus Andersson's public Inter font package proxy used for custom typography
    'caiyunapp.com',                 # Caiyun translation or weather tracking browser extension layouts
    'gwdang.com',                    # "Gouwudang" Chinese shopping comparison tracking helper framework
    'segment.com',                   # Twilio Segment data integration layer running inside user-side security plugins
    'stacysfinds.com',               # E-commerce plugin, blogging layout element, or browser discount assistant
    'xiaoxiaodediyi.xyz',            # Obfuscated ad-delivery tracking landing frame or adware domain hook
    'baydn.com',                     # Shanbay English language learning web assistant extension tracking code strings
    'wienslab.org',                  # External laboratory site context or resource bookmark widget references
    'wienslab.com',                  # Alternative commercial mapping address for the Wiens research lab framework
    'leoduo.cn',                     # Local Chinese image optimization utility or image processing toolbar script
    'editorialmanager.com',          # Aries Systems Editorial Manager journal manuscript review system hooks
    'facebook.net',                  # Meta/Instagram In-App browser trackers
    'facebook.com',                  # Meta/Instagram In-App browser trackers
    'pcm.js',                        # Meta Private Click Measurement
    'jd.com',                        # JD.com shopping extension injections
    'migaku.com',                    # Migaku language learning translation extension
    'threatspike.com',               # Corporate enterprise endpoint security tools
    'chrome-extension://',           # Random local Google Chrome user extensions
    'safari-extension://',           # Random local Apple Safari user extensions
    'moz-extension://',              # Random local Mozilla Firefox user extensions
    'ms-browser-extension'           # Random local Microsoft Edge user extensions
  ].freeze

  def create
    report = JSON.parse(request.body.read)

    blocked_uri = report.dig('csp-report', 'blocked-uri').to_s
    if IGNORED_EXTENSIONS.any? { |ext| blocked_uri.include?(ext) }
      Rails.logger.warn("CSP ignored report for #{report['csp-report']['effective-directive']}: '#{
        report['csp-report']['blocked-uri']}' - #{report['csp-report']['document-uri']} ")
      head :no_content and return
    end

    CspReport.create(
      ip: request.remote_ip,
      user_agent: request.user_agent,
      blocked_uri: report['csp-report']['blocked-uri'],
      url: report['csp-report']['document-uri'],
      directive: report['csp-report']['effective-directive'],
      status_code: report['csp-report']['status-code'],
      report: report
    )
    head :ok
  end
end
