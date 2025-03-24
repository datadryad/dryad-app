
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
Rack::Attack.reset!
```


To find entries for a particular IP:
```
cd ~/deploy/shared/tmp/cache
find . -name "*95.92.252.102*"
```

Individual entries may be deleted to reset them.
