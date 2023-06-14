# terraform-mds

Provision MySQL Database Service (MDS) and Heatwave with Terraform.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/khkwon01/terraform-mds/archive/refs/tags/mds-heatwave-v2.6.0.zip)


# Demo Cloud Architecture diagram
If you execute the above terraform code in oci, it make the below service like diagram which the heatwave node is disabled.
<img width="802" alt="image" src="https://user-images.githubusercontent.com/8789421/213102145-3a14870d-7a6a-4a54-a1fb-d2eee02c4d58.png">

한국 춘천센터 기준 위에 그림처럼 구성 되는데 대략 25분 정도 소요됨.

# HeatWave 기본동작
![image](https://github.com/khkwon01/terraform-mds-heatwave/assets/8789421/85a41d10-0f19-405d-a883-f4af7b657151)

# HeatWave OLTP for accelerated processing   
(Public Document : https://dev.mysql.com/doc/heatwave/en/mys-hw-analytics.html)
- HeatWave 사용하기 위한 조건    
  - 데이터 load --> MDS --> HeatWave Node
  - table은 innodb table 사용 가능 (변경 : alter table table명 engine=InnoDb)
  - table에 PK(1개 컬럼, 숫자타입 권장)는 필수 (변경 : alter table table명 add primary key (컬럼))
  - table 컬럼 크기는 65532 byte 이하, 테이블당 컬럼 개수는 900 이하
- 데이터 Load
  - HeatWave load시 데이터 compression disable   
    - set session rapid_compression=OFF 
  - HeatWave 데이터 load/unload
    - auto load schema : CALL sys.heatwave_load(JSON_ARRAY("tpch"),NULL);     # dry run시 NULL 대신 JSON_OBJECT("mode","dryrun")
    - 수동 load table : alter table orders secondary_load;
    - 수동 unload table : alter table orders secondary_unload;
  - HeatWave 데이터 load시 오류체크 (auto load시 에러 정보 출력)
    - 에러 확인 : SELECT log FROM sys.heatwave_autopilot_report WHERE type="error";
    - 경고 확인 : SELECT log FROM sys.heatwave_autopilot_report WHERE type="warn";
  - 변경된 데이터 Propagation 조건 (MDS --> Heatwave Node, batch transactions)
    - 매 200ms
    - change propagation buffer가 64MB 도달할때
    - 변경된 데이터가 heatwave query에서 사용될때       
    > * 상태 체크 (on이면 정상)     
      SELECT VARIABLE_VALUE
      FROM performance_schema.global_status
      WHERE VARIABLE_NAME = 'rapid_change_propagation_status';   
          
# ML Demo scenario
- HeatWave : https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/run-workshop?p210_wid=3157
- ML Test
  - IRIS 머신러닝
    - 실습 URL : https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/run-workshop?p210_wid=3306&p210_wec=&session=374748331881
  - Census 머신러닝
    - 데이터 다운로드
      - wget https://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.data --output-document=census_train.csv
      - wget https://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.test --output-document=census_test.csv
    - DB 작업
      ```
      mysqlsh --uri admin@<your ip> --mc --sql   # class mode
      DROP DATABASE IF EXISTS census;
      CREATE DATABASE census;
      USE census;

      // 원본 SQL
      CREATE TABLE census_train ( age INT, workclass VARCHAR(255), fnlwgt INT, education VARCHAR(255), `education-num` INT, `marital-status` VARCHAR(255), occupation VARCHAR(255), relationship VARCHAR(255), race VARCHAR(255), sex VARCHAR(255), `capital-gain` INT, `capital-loss` INT, `hours-per-week` INT, `native-country` VARCHAR(255), revenue VARCHAR(255));
      CREATE TABLE census_test LIKE census_train;
      
      // 변경 SQL (PK 포함)
      CREATE TABLE census_train_tmp ( age INT, workclass VARCHAR(255), fnlwgt INT, education VARCHAR(255), `education-num` INT, `marital-status` VARCHAR(255), occupation VARCHAR(255), relationship VARCHAR(255), race VARCHAR(255), sex VARCHAR(255), `capital-gain` INT, `capital-loss` INT, `hours-per-week` INT, `native-country` VARCHAR(255), revenue VARCHAR(255));
      CREATE TABLE census_test_tmp LIKE census_train_tmp;
      
      CREATE TABLE census_train (id INT primary key auto_increment, age INT, workclass VARCHAR(255), fnlwgt INT, education VARCHAR(255), `education-num` INT, `marital-status` VARCHAR(255), occupation VARCHAR(255), relationship VARCHAR(255), race VARCHAR(255), sex VARCHAR(255), `capital-gain` INT, `capital-loss` INT, `hours-per-week` INT, `native-country` VARCHAR(255), revenue VARCHAR(255)); 
      CREATE TABLE census_test (id INT primary key auto_increment, age INT, workclass VARCHAR(255), fnlwgt INT, education VARCHAR(255), `education-num` INT, `marital-status` VARCHAR(255), occupation VARCHAR(255), relationship VARCHAR(255), race VARCHAR(255), sex VARCHAR(255), `capital-gain` INT, `capital-loss` INT, `hours-per-week` INT, `native-country` VARCHAR(255), revenue VARCHAR(255)); 
      ``` 
    - 데이터 import
      ```
      \js
      // 원본 SQL
      util.importTable("census_train.csv",{table: "census_train", dialect: "csv-unix", skipRows:1})
      util.importTable("census_test.csv",{table: "census_test", dialect: "csv-unix", skipRows:1})      
      
      // 변경 SQL (PK포함)
      util.importTable("census_train.csv",{table: "census_train_tmp", dialect: "csv-unix", skipRows:1})
      util.importTable("census_test.csv",{table: "census_test_tmp", dialect: "csv-unix", skipRows:1})
      
      insert into census_train values (age, workclass, fnlwgt, education, `education-num`, `marital-status`, occupation, relationship, race, sex, `capital-gain`, `capital-loss`, `hours-per-week`, `native-country`, revenue) select * from census_train_tmp;
      insert into census_test (age, workclass, fnlwgt, education, `education-num`, `marital-status`, occupation, relationship, race, sex, `capital-gain`, `capital-loss`, `hours-per-week`, `native-country`, revenue) select * from census_test_tmp;
      ```
    - ML 
      ```
      \sql
      -- Set globa variables
      set @census_model = NULL;
      
      -- Train the model
      CALL sys.ML_TRAIN('census.census_train', 'revenue', JSON_OBJECT('task', 'classification'), @census_model);
      
      // PK 제외하고 싶을 경우
      CALL sys.ML_TRAIN('census.census_train', 'revenue', JSON_OBJECT('task', 'classification', 'exclude_column_list', JSON_ARRAY('id')), @census_model);
      
      -- Load the model into HeatWave
      CALL sys.ML_MODEL_LOAD(@census_model, NULL);
      
      -- Score the model on the test data
      -- CALL sys.ML_SCORE('census.census_test', 'revenue', @census_model, 'balanced_accuracy', @score);
      -- CALL sys.ML_SCORE('census.census_test', 'revenue', @census_model, 'balanced_accuracy', @score, NULL);
      CALL sys.ML_SCORE('census.census_train', 'revenue', @census_model, 'accuracy', @score, NULL);
      CALL sys.ML_SCORE('census.census_train', 'revenue', @census_model, 'balanced_accuracy', @score, JSON_OBJECT('threshold',0));
      
      -- Select score
      select @score;
      
      -- See the detail of model
      SELECT JSON_Pretty(model_explanation) FROM ML_SCHEMA_admin.MODEL_CATALOG WHERE model_handle=@census_model;
      
      -- Specify 1 row example
      set @row_input = '{"age": 38,"workclass": "Private","fnlwgt": 89814,"education": "HS-grad","education-num": 9,"marital-status": "Married-civ-spouse","occupation": "Farming-fishing","relationship": "Husband","race": "White","sex": "Male","capital-gain": 0,"capital-loss": 0,"hours-per-week": 50,"native-country": "United-States"}' ;
      
      -- predict for 1 row
      SELECT json_pretty(sys.ML_PREDICT_ROW(@row_input, @census_model, NULL));
      
      -- explain for 1 row
      SELECT JSON_Pretty(sys.ML_EXPLAIN_ROW(@row_input, @census_model, JSON_OBJECT('prediction_explainer', 'permutation_importance')));
      
      -- predict for whole test table
      CALL sys.ML_PREDICT_TABLE('census.census_test', @census_model, 'census.census_test_predictions', NULL);
      
      -- explain for whole test table
      CALL sys.ML_EXPLAIN_TABLE('census.census_test', @census_model, 'census.census_test_predictions', JSON_OBJECT('prediction_explainer', 'permutation_importance'));
      
      -- unload model
      CALL sys.ML_MODEL_UNLOAD(@census_model);
      ```
  - Electricity consumption(time forcasting) 머신러닝
    - 데이터 다운로드
      wget 
