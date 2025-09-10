Set up Amazon AWS CloudWatch Agent
====================

AWS CloudWatch Agent is installed on all servers and is used for:
- Serving metrics related to disk usage.
- Stream log files to Cloudwatch.
- Attach SSMInstanceProfile (or a role with the required policies) to your EC2 instance.

To install the agent, follow the steps below:
-----------------------------

```
sudo yum install amazon-cloudwatch-agent
cd /opt/aws/amazon-cloudwatch-agent/
```

Configuration file for streaming disk usage metrics
-----------------------------
```
sudo vim etc/amazon-cloudwatch-agent.d/metrics_config.json
```

```json
{
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
      "InstanceId": "${aws:InstanceId}",
      "InstanceType": "${aws:InstanceType}"
    },
    "aggregation_dimensions" : [["InstanceId"]],
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "disk_used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      }
    }
  }
}
```

Configuration file for streaming log files
-----------------------------
```
sudo vim etc/amazon-cloudwatch-agent.d/logs_config.json
```
```json
{
  "agent": {
    "metrics_collection_interval": 1,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/ec2-user/deploy/current/log/production.log",
            "log_group_class": "STANDARD",
            "log_group_name": "production-web",
            "log_stream_name": "{ip_address}_{instance_id}",
            "retention_in_days": 30
          },
          {
            "file_path": "/home/ec2-user/deploy/current/log/api_requests.log",
            "log_group_class": "STANDARD",
            "log_group_name": "production-api",
            "log_stream_name": "{ip_address}_{instance_id}",
            "retention_in_days": 30
          },
          {
            "file_path": "/home/ec2-user/deploy/current/log/crons/*.log",
            "log_group_class": "STANDARD",
            "log_group_name": "production-others",
            "log_stream_name": "{ip_address}_{instance_id}",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "traces": {
    "buffer_size_mb": 3,
    "concurrency": 8,
    "insecure": false,
    "traces_collected": {
      "xray": {
        "bind_address": "127.0.0.1:2000",
        "tcp_proxy": {
          "bind_address": "127.0.0.1:2000"
        }
      }
    }
  }
}
```

To create symlinks for all `others` log files, `cd` into application `logs` 
and create the `crons/`folder and run the following command
```
cd ~/deploy/current/log/
mkdir crons
cd crons
ln -s ../!(production.log*|api_requests.log|crons) ./
```
  
Start and enable the service
-----------------------------

Change ownership to files. The service will run as `cwagent` user.
```
cd /opt/aws/amazon-cloudwatch-agent/
sudo chown cwagent:cwagent -R etc
sudo chown cwagent:cwagent -R logs
sudo chown cwagent:cwagent -R var

sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl restart amazon-cloudwatch-agent
```

For verification, there should be no errors:
```
tail -f logs/amazon-cloudwatch-agent.log 
```
