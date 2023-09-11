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
