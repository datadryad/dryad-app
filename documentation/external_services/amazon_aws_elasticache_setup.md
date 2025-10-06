
Steps for setting up ElastiCache instances 
======================================================================

- Change eviction policy configuration default value
    - Create a new parameter group
    - Edit the following parameter in this group and set
        - `maxmemory-policy allkeys-lru`
    
- Create a cache instance for rails application (including Sidekiq), one each environment on port `6380`
- Create a cache instance for RackAttack on port `6381` (one for all environments)
- Create and configure proper security groups to allow EC2 machines to access the instances

### NOTE:
> Select the newly created parameter group to each instance on creation.
>
> Adding after the instance is created requires node reboot, and this will clear node content.

### Local installation with Docker
You can use [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)

Run the following commands in the terminal to create the two instances:

```aiignore
docker run -d --name dryad-valkey -p 6380:6379 valkey/valkey:latest
docker run -d --name rack-attack-valkey -p 6381:6379 valkey/valkey:latest
```
