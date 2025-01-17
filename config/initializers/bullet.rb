if Rails.env.local?
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable        = true
      Bullet.alert         = false
      Bullet.bullet_logger = true
      Bullet.console       = true
      Bullet.rails_logger  = true
      Bullet.add_footer    = true
    end
  end
end
