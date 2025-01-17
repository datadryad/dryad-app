if Rails.env.local?
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable        = true
      Bullet.alert         = false
      Bullet.bullet_logger = true
      Bullet.console       = true
      Bullet.rails_logger  = true
      Bullet.add_footer    = true
      Bullet.add_safelist  :type => :unused_eager_loading, :class_name => "StashEngine::User", :association => :roles
      Bullet.add_safelist  :type => :unused_eager_loading, :class_name => "StashEngine::Identifier", :association => :resources
    end
  end
end
