
Rack Attack
=============

We use Rack Attack to throttle usage on the servers and manage lists of banned IPs.

Configuring
------------

All throttling and bans are managed in `config/initializers/rack_attack.rb`

Managing the throttled/banned list
----------------------------------

Tracking for each rule is managed in the Rails cache.

To reset the entire cache:
```
rails_console.sh
Rack::Attack.cache.store.flushdb
```

To find entries for a particular IP:
```
rails_console.sh

Rack::Attack.cache.store.keys.select{|a| a.include?('95.92.252.102')}
=> ["rack::attack:682:file_downloads_per_month:file_download_per_month_95.92.252.102"]

Rack::Attack.cache.store.get("rack::attack:682:file_downloads_per_month:file_download_per_month_95.92.252.102")
=> "5"
```

Individual entries may be deleted to reset them.
```
rails_console.sh
Rack::Attack.cache.store.delete("existing_key_name_here")
```

Check if a key exists:
```
rails_console.sh
Rack::Attack.cache.store.exists?("key_name_here")
```
