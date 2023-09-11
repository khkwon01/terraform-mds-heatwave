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

### 2) Encryption
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

