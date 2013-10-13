# Amazon RDS (for MySQL) input plugin

## Overview
***Amazon Web Services RDS(MySQL) general_log and slow_log input plugin.  

##Installation

    $ fluent-gem install fluent-plugin-rds-log

## RDS Setting

[Working with MySQL Database Log Files / aws documentation](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_LogAccess.Concepts.MySQL.html)

- Set the `log_output` parameter to `TABLE` to write the logs to a database table.
- Set the `slow_query_log` parameter to `1`
- Set the `general_log` parameter to `1`
- setting `min_examined_row_limit`
- setting `long_query_time`

## Configuration

```config
<source>
  type rds_log
  log_type <slow_log | general_log>
  host [RDS Hostname]
  username [RDS Username]
  password [RDS Password]
  refresh_interval [number]
  auto_reconnect [true|false]
  tag [tag-name]
</source>
```

### Example GET RDS general_log

```config
<source>
  type rds_log
  log_type general_log
  host endpoint.abcdefghijkl.ap-northeast-1.rds.amazonaws.com
  username rds_user
  password rds_password
  refresh_interval 30
  auto_reconnect true
  tag rds-general-log
</source>

<match rds-general-log>
  type file
  path /var/log/rds-general-log
</match>
```

