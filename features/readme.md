## 1. MDS 지원 feature 리스트 (8.1.0 or 8.0.34)
| 구분 | 지원여부 | Plugin 이름 | 설명 | 기타 |
|---------------|:--------|:------------------|:----------------------------------------------------------------|:--------------------------|
| `Masking`     | 지원     | data_masking      | 주민번호와 같은 민감한 데이터에 대한 masking 또는 비식별화 기능               |                           |
| `TDE`         | 부분지원  |                   | 데이터가 저장되어 있는 물리적은 파일에 대한 암/복호화 지원 (Oracle Managed 방식)| Customer Key 방식은 나중지원  |
| `Encryption`  | 지원     |                   | 테이블 저장 데이터에 대해 암/복호화 기능 지원                              |     |
| `Firewall`    | 지원안됨  |                   | 서비스 SQL white list 기반에 bad SQL에 대해 blocking, detecting       |     |
| `Audit`       | 지원     | audit_log         | 사용자 또는 DB 활동에 대한 audit 기능 제공                              |     |
| `Thread Pool` | 지원     | thread_pool       | 대용량 사용자 및 트래픽 발생시 안정적인 성능 유지                           |     |
| `HA`          | 지원     | group_replication | Innodb Cluster 서비스를 기반으로 HA 지원 (3대)                         |     |
| `Monitor`     | 지원예정  |                   | Database Management > Fleet Summary > MySQL Database (Ashburn)   |     |
| `HeatWave`    | 지원     | RAPID             | OLTP, OLAP, ML 지원                                               |     |
| `LakeHouse`   | 지원     | lakehouse         | Lakehouse 지원                                                    |     |


## 2. 각 Features 사용 예제 
### 1) Masking 
```
 MySQL  10.0.20.169:33060+ ssl  SQL > select gen_rnd_us_phone();
+--------------------+
| gen_rnd_us_phone() |
+--------------------+
| 1-555-431-1161     |
+--------------------+

 MySQL  10.0.20.169:33060+ ssl  airportdb  SQL > select mask_inner(emailaddress, 1, 1) from employee limit 10;
+---------------------------------------+
| mask_inner(emailaddress, 1, 1)        |
+---------------------------------------+
| RXXXXXXXXXXXXXXXXXXXXXXXXXm           |
| PXXXXXXXXXXXXXXXXXXXXXXXXXXt          |
| FXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXt      |
| TXXXXXXXXXXXXXXXXXXXXXXXXXm           |
| DXXXXXXXXXXXXXXXXXXXXXXXXXXXXXm       |
| BXXXXXXXXXXXXXXXXXXXXXXXXXXh          |
| FXXXXXXXXXXXXXXXXXXXXXXXh             |
| AXXXXXXXXXXXXXXXXXXXXm                |
| JXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXm |
| TXXXXXXXXXXXXXXXXXXXl                 |
+---------------------------------------+
```
### 2) Encryption
```
MySQL  10.0.20.169:33060+ ssl  airportdb  SQL > select AES_ENCRYPT('text',UNHEX('F3229A0B371ED2D9441B830D21A390C3'));

+---------------------------------------------------------------+
| AES_ENCRYPT('text',UNHEX('F3229A0B371ED2D9441B830D21A390C3')) |
+---------------------------------------------------------------+
| 0x916C1053F731A5934773483F981DDAF6                            |
+---------------------------------------------------------------+

 MySQL  10.0.20.169:33060+ ssl  airportdb  SQL > select AES_ENCRYPT('text', UNHEX(SHA2('My secret passphrase',512)));
+--------------------------------------------------------------+
| AES_ENCRYPT('text', UNHEX(SHA2('My secret passphrase',512))) |
+--------------------------------------------------------------+
| 0x557F8E81CBBBB2515A33500768018C3C                           |
+--------------------------------------------------------------+
1 row in set, 1 warning (0.0006 sec)

 MySQL  10.0.20.169:33060+ ssl  airportdb  SQL > SELECT MD5('testing');
+----------------------------------+
| MD5('testing')                   |
+----------------------------------+
| ae2b1fca515949e5d54fb22b8ed95575 |
+----------------------------------+
1 row in set (0.0005 sec)

 MySQL  10.0.20.169:33060+ ssl  airportdb  SQL > SELECT SHA2('abc', 224);
+----------------------------------------------------------+
| SHA2('abc', 224)                                         |
+----------------------------------------------------------+
| 23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7 |
+----------------------------------------------------------+
```
### 3) Audit
```
 MySQL  10.0.20.169:33060+ ssl  mysql_audit  SQL > show variables like 'audit%';
+--------------------------------------+---------------------+
| Variable_name                        | Value               |
+--------------------------------------+---------------------+
| audit_log_buffer_size                | 10485760            |
| audit_log_compression                | GZIP                |
| audit_log_connection_policy          | ALL                 |
| audit_log_current_session            | OFF                 |
| audit_log_database                   | mysql_audit         |
| audit_log_disable                    | OFF                 |
| audit_log_encryption                 | NONE                |
| audit_log_exclude_accounts           |                     |
| audit_log_file                       | /db/audit/audit.log |
| audit_log_filter_id                  | 0                   |
| audit_log_flush                      | OFF                 |
| audit_log_flush_interval_seconds     | 60                  |
| audit_log_format                     | JSON                |
| audit_log_format_unix_timestamp      | ON                  |
| audit_log_include_accounts           |                     |
| audit_log_max_size                   | 5368709120          |
| audit_log_password_history_keep_days | 0                   |
| audit_log_policy                     | ALL                 |
| audit_log_prune_seconds              | 604800              |
| audit_log_read_buffer_size           | 32768               |
| audit_log_rotate_on_size             | 52428800            |
| audit_log_statement_policy           | ALL                 |
| audit_log_strategy                   | ASYNCHRONOUS        |
+--------------------------------------+---------------------+

 MySQL  10.0.20.169:33060+ ssl  mysql_audit  SQL > SELECT audit_log_filter_set_filter('log_all', '{ "filter": { "log": true } }');
+-------------------------------------------------------------------------+
| audit_log_filter_set_filter('log_all', '{ "filter": { "log": true } }') |
+-------------------------------------------------------------------------+
| OK                                                                      |
+-------------------------------------------------------------------------+

 MySQL  10.0.20.169:33060+ ssl  mysql_audit  SQL > SELECT audit_log_filter_set_user('%', 'log_all');
+-------------------------------------------+
| audit_log_filter_set_user('%', 'log_all') |
+-------------------------------------------+
| OK                                        |
+-------------------------------------------+

 MySQL  10.0.20.169:33060+ ssl  mysql_audit  SQL > SELECT audit_log_read('{ "start": { "timestamp": "2023-09-11 07:00:00"}, "max_array_length": 500 }')\G;
*************************** 1. row ***************************
audit_log_read('{ "start": { "timestamp": "2023-09-11 07:00:00"}, "max_array_length": 500 }'): [ {"timestamp":"2023-09-11 07:37:15","id":0,"ts":1694417835,"class":"audit","event":"startup","connection_id":35,"account":{"user":"ociadmin","host":"localhost"},"login":{"user":"ociadmin","os":"","ip":"127.0.0.1","proxy":""},"startup_data":{"server_id":1771736919,"os_version":"x86_64-Linux","mysql_version":"8.1.0-u3-cloud","args":["/usr/sbin/mysqld","--admin_port=7306","--binlog_row_event_max_size=16384","--core_file","--datadir=/db/data","--event_scheduler=OFF","--innodb_data_home_dir=/db/data/","--innodb_log_group_home_dir=/db/redo","--innodb_tmpdir=/db/tmp","--innodb_undo_directory=/db/undo","--innodb_validate_tablespace_paths=OFF","--log_bin_index=/db/binlogs/binary-log.index","--log_error=/db/log/error.log","--log_error_suppression_list=MY-012111","--log_error_verbosity=3","--partial_revokes=ON","--relay_log_index=/db/replication/r

 MySQL  10.0.20.169:33060+ ssl  mysql_audit  SQL > SELECT JSON_PRETTY(CONVERT(audit_log_read('{ "start": { "timestamp": "2023-09-11 07:00:00"}, "max_array_length": 500 }') using utf8mb4))\G;
*************************** 1. row ***************************
JSON_PRETTY(CONVERT(audit_log_read('{ "start": { "timestamp": "2023-09-11 07:00:00"}, "max_array_length": 500 }') using utf8mb4)): [
  {
    "id": 0,
    "ts": 1694417835,
    "class": "audit",
    "event": "startup",
    "login": {
      "ip": "127.0.0.1",
      "os": "",
      "user": "ociadmin",
      "proxy": ""
    },


 MySQL  10.0.20.169:33060+ ssl  mysql_audit  SQL > SELECT @@server_uuid as server_uuid, ts, class, event, login_ip,login_user,connection_id,
                                                ->  status,connection_type,_client_name,_client_version,
                                                ->  command,sql_command,command_status
                                                -> FROM
                                                -> JSON_TABLE
                                                -> ( AUDIT_LOG_READ( '{ "start": {"timestamp": "2023-08-16 15:33:37"}, "max_array_length": 10 }' ), 
                                                ->   '$[*]'
                                                ->   COLUMNS
                                                ->   ( ts TIMESTAMP PATH '$.timestamp',
                                                ->     class VARCHAR(20) PATH '$.class',
                                                ->     event VARCHAR(80) PATH '$.event',      
                                                ->     login_ip VARCHAR(200) PATH '$.login.ip',
                                                ->     login_user VARCHAR(200) PATH '$.login.user',
                                                ->     connection_id VARCHAR(80) PATH '$.connection_id',
                                                ->     status INT PATH '$.connection_data.status',
                                                ->     connection_type VARCHAR(40) PATH '$.connection_data.connection_type',
                                                ->     _client_name VARCHAR(80) PATH '$.connection_data.connection_attributes._client_name',
                                                ->     _client_version VARCHAR(80) PATH '$.connection_data.connection_attributes._client_version',
                                                ->     command VARCHAR(40) PATH '$.general_data.command',
                                                ->     sql_command VARCHAR(40) PATH '$.general_data.sql_command',
                                                ->     command_status VARCHAR(40) PATH '$.general_data.status'
                                                ->    )) as audit_log;
+--------------------------------------+---------------------+-------+----------+-----------+------------+---------------+--------+-----------------+--------------+-----------------+---------+-------------+----------------+
| server_uuid                          | ts                  | class | event    | login_ip  | login_user | connection_id | status | connection_type | _client_name | _client_version | command | sql_command | command_status |
+--------------------------------------+---------------------+-------+----------+-----------+------------+---------------+--------+-----------------+--------------+-----------------+---------+-------------+----------------+
| 039a1294-5076-11ee-86b7-02001700c8ea | 2023-09-11 07:37:15 | audit | startup  | 127.0.0.1 | ociadmin   | 35            |   NULL | NULL            | NULL         | NULL            | NULL    | NULL        | NULL           |
| 039a1294-5076-11ee-86b7-02001700c8ea | 2023-09-11 07:37:55 | audit | shutdown | NULL      | NULL       | 0             |   NULL | NULL            | NULL         | NULL            | NULL    | NULL        | NULL           |
| 039a1294-5076-11ee-86b7-02001700c8ea | 2023-09-11 07:37:59 | audit | startup  |           |            | 0             |   NULL | NULL            | NULL         | NULL            | NULL    | NULL        | NULL           |
| 039a1294-5076-11ee-86b7-02001700c8ea | 2023-09-11 07:38:39 | audit | shutdown | NULL      | NULL       | 0             |   NULL | NULL            | NULL         | NULL            | NULL    | NULL        | NULL           |
| 039a1294-5076-11ee-86b7-02001700c8ea | 2023-09-11 07:38:40 | audit | startup  |           |            | 0             |   NULL | NULL            | NULL         | NULL            | NULL    | NULL        | NULL           |
| 039a1294-5076-11ee-86b7-02001700c8ea | 2023-09-11 07:38:45 | audit | shutdown | NULL      | NULL       | 0             |   NULL | NULL            | NULL         | NULL            | NULL    | NULL        | NULL           |
| 039a1294-5076-11ee-86b7-02001700c8ea | 2023-09-11 07:38:48 | audit | startup  |           |            | 0             |   NULL | NULL            | NULL         | NULL            | NULL    | NULL        | NULL           |
| 039a1294-5076-11ee-86b7-02001700c8ea | NULL                | NULL  | NULL     | NULL      | NULL       | NULL          |   NULL | NULL            | NULL         | NULL            | NULL    | NULL        | NULL           |
+--------------------------------------+---------------------+-------+----------+-----------+------------+---------------+--------+-----------------+--------------+-----------------+---------+-------------+----------------+
8 rows in set (0.0018 sec)
```

