# terraform-mds

Provision MySQL Database Service (MDS) and Heatwave with Terraform.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/khkwon01/terraform-mds/archive/refs/tags/mds-heatwave-v3.3.0.zip)


# Demo Cloud Architecture diagram
If you execute the above terraform code in oci, it make the below service like diagram which the heatwave node is disabled.
<img width="802" alt="image" src="https://user-images.githubusercontent.com/8789421/213102145-3a14870d-7a6a-4a54-a1fb-d2eee02c4d58.png">

한국 춘천센터 기준 위에 그림처럼 구성 되는데 대략 25분 정도 소요됨.

# HeatWave 기본동작
(관련 Doc URL : https://dev.mysql.com/doc/heatwave/en/mys-hw-introduction.html)
![image](https://github.com/khkwon01/terraform-mds-heatwave/assets/8789421/85a41d10-0f19-405d-a883-f4af7b657151)

- In-Memory Hybrid-Columnar Format
- Massively Parallel Architecture    
![image](https://github.com/khkwon01/terraform-mds-heatwave/assets/8789421/c52407cd-2815-4141-aab8-5688e1e71c4f)     
- Push-Based Vectorized Query Processing

# HeatWave OLAP for accelerated processing (v8.0.34 기준)
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
    - auto load schema : CALL sys.heatwave_load(JSON_ARRAY("tpch"),NULL);  // dry run시 NULL 대신 JSON_OBJECT("mode","dryrun")
      - auto parallel load 예제 : https://dev.mysql.com/doc/heatwave/en/mys-hw-auto-parallel-load-examples.html
    - 수동 load table : alter table orders secondary_load;
    - 수동 unload table : alter table orders secondary_unload;
  - HeatWave 데이터 load시 오류체크 (auto load시 에러 정보 출력, load 세션에서만 )
    - 에러 확인 : SELECT log FROM sys.heatwave_autopilot_report WHERE type="error";
    - 경고 확인 : SELECT log FROM sys.heatwave_autopilot_report WHERE type="warn";
  - load 진행 상태 확인
    - 데이터 load시 % 진행상태   
      SELECT VARIABLE_VALUE FROM performance_schema.global_status    
      WHERE VARIABLE_NAME = 'rapid_load_progress'; 
    - 데이터 load 상태 확인   
      SELECT NAME, LOAD_STATUS FROM performance_schema.rpd_tables, performance_schema.rpd_table_id    
      WHERE rpd_tables.ID = rpd_table_id.ID; 
  - 변경된 데이터 Propagation(동기화) 조건 (MDS --> Heatwave Node, batch transactions)
    - 매 200ms
    - change propagation buffer가 64MB 도달할때
    - 변경된 데이터가 heatwave query에서 사용될때       
    > * 상태 체크 (on이면 정상)     
      SELECT VARIABLE_VALUE
      FROM performance_schema.global_status
      WHERE VARIABLE_NAME = 'rapid_change_propagation_status';   

- HeatWave 노드 Query 수행
  - HeatWave 노드 Query offload 조건   
    **아래 조건이 만족하지 않으면, 수행되는 Query는 MDS에서 실행이 됨.**
    - query문중 select만 (insert ~ select, create table ~ select에서도 select만 사용가능)
    - query에 사용되는 table은 rapid 엔진으로 정의되고, heatwave로 load 되어야 함
    - autocommit은 enable 되어 있어야 함
    - query는 heatwave가 지원 가능한 타입을 사용해야만 하고 제약 사항을 피해야 함
      - 데이터 지원 타입 : https://dev.mysql.com/doc/heatwave/en/mys-hw-function-operator-reference.html
      - 제약 사항 : https://dev.mysql.com/doc/heatwave/en/mys-hw-limitations.html
  - HeatWave Query 수행
    - 실제 Heatwave 노드에서 Query 수행여부 사전체크   
      EXPLAIN SELECT O_ORDERPRIORITY, COUNT(*) AS ORDER_COUNT ~~   
      위 실행계획에서 extra 컬럼에 "using secondary engine RAPID" 라고 표시 되어야 사용가능
    - MDS와 HeatWave offload시 성능 비교
      - offload 쿼리 수행 (heatwave 노드에서 수행)
      - SET SESSION use_secondary_engine=OFF; (heatwave 사용 disable)
      - offload 쿼리 수행 (mds에서 수행)
    - HeatWave로 쿼리가 offload 안될 경우 troubleshooting     
      - query cost 기준 (> 100,000 커야 offload 됨)    
        빠른 Query가 HeatWave 노드로 offload 되는 것을 피하기 위해 query cost 기준을 넘어야 함    
        * 쿼리 cost 확인 절차   
          SET SESSION use_secondary_engine=OFF;   
          EXPLAIN select_query;    
          SHOW STATUS LIKE 'Last_query_cost';    
      - table이 heatwave로 load 되었는지 확인   
        SELECT NAME, LOAD_STATUS FROM performance_schema.rpd_tables,performance_schema.rpd_table_id   
        WHERE rpd_tables.ID = rpd_table_id.ID;
      - Query 수행시 out-of-memory 발생시    
        Heatwave는 memory 보다는 network usage에 맞춰 최적화가 되었기 때문에, 아래와 같은 명령어 변경이 가능    
        SET SESSION rapid_execution_strategy = MIN_MEM_CONSUMPTION;
      - query debug (Offload 되지 않은 이유확인)
        <pre>     
        SET SESSION optimizer_trace="enabled=on";    
        SET optimizer_trace_offset=-2;    
        explain query ~~    
        SELECT QUERY, TRACE->'$**.Rapid_Offload_Fails', TRACE->'$**.secondary_engine_not_used'     
        FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE;     
        </pre>
      - 수행 query history 확인   
        <pre>
        SELECT query_id,    
          JSON_EXTRACT(JSON_UNQUOTE(qkrn_text->'$**.sessionId'),'$[0]') AS session_id, 
          JSON_EXTRACT(JSON_UNQUOTE(qkrn_text->'$**.accumulatedRapidCost'),'$[0]') AS time_in_ns, 
          JSON_EXTRACT(JSON_UNQUOTE(qexec_text->'$**.error'),'$[0]') AS error_message
          FROM performance_schema.rpd_query_stats;
        </pre>
      - 수행 query offload 강제   
        시스템 설정 : set session use_secondary_engin = FORCED;   // select 쿼리가 heatwave offload 되지 않으면 에러    
        쿼리 hint : select /*+ SET_VAR(use_secondary_engine = FORCED) */ ~~ from    
    - 기존 Heatwave query history 쿼리 기반 advisor 수행 (기존 수행된 내용중 개선 사항 확인)    
       CALL sys.heatwave_advisor(JSON_OBJECT("target_schema",JSON_ARRAY("tpch_1024")));  // schema 기준 확인    
       CALL sys.heatwave_advisor(JSON_OBJECT("query_insights", TRUE));   // 쿼리 기준 확인
    - HeatWave 노드 추가 필요성 확인
      - 데이터 사이즈가 400GB(비압축, 압축 :800G)보다 클 경우 HeatWave 노드 추가    
        SELECT table_schema "DB Name",
            ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) "DB Size in MB" 
        FROM information_schema.tables 
        GROUP BY table_schema; 
      - sys.heatwave_advisor 수행후 결과 검토시 추가
      - HeatWave 노드에서 estimate node 수행후 권장시 추가
        ![image](https://github.com/khkwon01/terraform-mds-heatwave/assets/8789421/3ea563ef-acbb-465c-8a36-2945de9729af)    
- HeatWave OLAP Demo     
  (참고자료 : https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/run-workshop?p210_wid=3157)    
  - 테스트 데이터 다운로드
    ```
    cd /home/opc
    wget -O airport-db.zip https://bit.ly/3pZ1PiW
    unzip airport-db.zip 
    cd airport-db
    ```
  - 테스트 데이터 HeatWave MDS로 import
    ```
    mysqlsh --user=admin --password=Welcome#1 --host=<heatwave_private_ip_address> --port=3306 --js
    util.loadDump("/home/opc/airport-db", {dryRun: false, threads: 8, resetProgress:true, ignoreVersion:true})
    ```
  - 테스트 데이터 HeatWave Node로 load
    ```
    CALL sys.heatwave_load(JSON_ARRAY('airportdb'), NULL);
    // load 상태 확인    
    SELECT NAME, LOAD_STATUS FROM performance_schema.rpd_tables,performance_schema.rpd_table_id WHERE rpd_tables.ID = rpd_table_id.ID;
    ```
  - olap 속도 테스트
    ```
    USE airportdb;
    SET SESSION use_secondary_engine=off;
    SELECT
    airline.airlinename,
    AVG(datediff(departure,birthdate)/365.25) as avg_age,
    count(*) as nb_people
    FROM
    booking, flight, airline, passengerdetails
    WHERE
    booking.flight_id=flight.flight_id AND
    airline.airline_id=flight.airline_id AND
    booking.passenger_id=passengerdetails.passenger_id AND
    country IN ("SWITZERLAND", "FRANCE", "ITALY")
    GROUP BY
    airline.airlinename
    ORDER BY
    airline.airlinename, avg_age
    LIMIT 10;

    SET SESSION use_secondary_engine=on;
    SELECT
    airline.airlinename,
    AVG(datediff(departure,birthdate)/365.25) as avg_age,
    count(*) as nb_people
    FROM
    booking, flight, airline, passengerdetails
    WHERE
    booking.flight_id=flight.flight_id AND
    airline.airline_id=flight.airline_id AND
    booking.passenger_id=passengerdetails.passenger_id AND
    country IN ("SWITZERLAND", "FRANCE", "ITALY")
    GROUP BY
    airline.airlinename
    ORDER BY
    airline.airlinename, avg_age
    LIMIT 10;
    ```
# HeatWave Lakehouse
  - Lakehouse Demo
    - Run MySQL autopilot in object store using mysqlshell
      ```
      SET @db_list = '["test"]'
      SET @tables_list = '[{
                             "db_name": "test",
                             "tables": [{
                                  "table_name": "supplier",
                                  "dialect": { "format": "csv", "field_delimiter": "|", "record_delimiter": "|\\n",
                                  "is_strict_mode": false ),
                                  "file": [{"par": "https://objectstorage.us-ashburn-1.oraclecloud.com/p/~~~.csv"}] }]
                           }]'       // or "file": [{"region": "us-ashburn-1", "namespace": "mysqlse", "bucket": "test", "prefix": "test/test_"

      SET @options = JSON_OBJECT('mode', 'normal', 'policy', 'disable_supported_columns', 'external_tables', CAST(@tables_list AS JSON));
      CALL sys.heatwave_load(@db_list, @options) 
      ```
    - Execute DDLs generated by Autopilot
    - Query accross file and table
      
# ML Demo scenario
- ML 사용 위한 조건
  - Model catalog 정보는 ML_SCHEMA_user명으로 생성됨 (참고 joe.smith와 같은 user명은 사용불가)  
  - ML용 테이블 데이터는 10GB, 100 million rows, 900 columns를 초과 할 수 없음
  - 너무 많은 메모리를 사용하는 걸 피하기 위해 Heatwave에 모델 로드는 3개까지 가능함
  - ML 모델 사이즈는 900MB이상은 지원하지 않으며, 초과시 에러가 발생
  - ML query progress 모니터링은 현재 지원하지 않음
  - ML_EXPLAIN_TABLE, ML_PREDICT_TABLE은 compute 리소스가 많이 소요됨으로, 큰 사이즈에 테이블을 작은 테이블(10 ~ 100 rows)로 분리하여 수행하는 걸 권장
  - Ctrl+C를 통한 작업 취소는 ML_TRAIN, ML_EXPLAIN_ROW, ML_EXPLAIN_TABLE만 지원
  - ML_EXPLAIN_* 는 가장 연관성이 큰 100개 features로 제한
  - 동시에 HeatWave analytics와 AutoML 쿼리는 지원되지 않음 (하나가 끝나야 다른 쿼리가 수행, analytics 쿼리가 우선함)
  - AWS는 HeatWave.256GB shape만 AutoML를 지원
  - AutoML에서 지원하는 테이블 데이터 타입은 아래와 같음    
    https://dev.mysql.com/doc/heatwave/en/mys-hwaml-supported-data-types.html
    
- ML Test
  - IRIS 머신러닝
    - 실습 URL : https://apexapps.oracle.com/pls/apex/r/dbpm/livelabs/run-workshop?p210_wid=3306&p210_wec=&session=374748331881
    - DB 및 ML 작업
      ```
      // iris 데이터 파일 다운로드 (위치 data/iris_ml_data.sql)
      mysqlsh --uri admin@<your ip> --sql
      source iris_ml_data.sql

      // 모델 훈련
      CALL sys.ML_TRAIN('ml_data.iris_train', 'class',JSON_OBJECT('task', 'classification'), @iris_model);

      // 생성된 모델 확인
      SELECT model_id, model_handle, train_table_name FROM ML_SCHEMA_admin.MODEL_CATALOG;

      // Heatwave 모델 load
      CALL sys.ML_MODEL_LOAD(@iris_model, NULL);

      // 개별 row predict 테스트
      SET @row_input = JSON_OBJECT("sepal length", 7.3, "sepal width", 2.9, "petal length", 6.3, "petal width", 1.8);
      SELECT sys.ML_PREDICT_ROW(@row_input, @iris_model, NULL);
      // 개별 row 예측 결과 설명 (explain)
      SELECT sys.ML_EXPLAIN_ROW(@row_input, @iris_model, JSON_OBJECT('prediction_explainer', 'permutation_importance'));

      // table predict 테스트
      CALL sys.ML_PREDICT_TABLE('ml_data.iris_test', @iris_model, 'ml_data.iris_predictions', NULL);
      // table 예측 결과 설명
      CALL sys.ML_EXPLAIN_TABLE('ml_data.iris_test',@iris_model,'ml_data.iris_explanations', JSON_OBJECT('prediction_explainer', 'permutation_importance'));

      // 모델 정확도 확인
      CALL sys.ML_SCORE('ml_data.iris_validate', 'class', @iris_model, 'balanced_accuracy', @score, NULL);
      SELECT @score;
      
      // 모델 unload
      CALL sys.ML_MODEL_UNLOAD(@iris_model);
      ```
  - Census 머신러닝
    - 데이터 다운로드
      - wget https://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.data --output-document=census_train.csv
      - wget https://archive.ics.uci.edu/ml/machine-learning-databases/adult/adult.test --output-document=census_test.csv
    - DB 및 ML 작업
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
      -- CALL sys.ML_SCORE('census.census_train', 'revenue', @census_model, 'balanced_accuracy', @score, JSON_OBJECT('threshold',0));
      
      -- Select score
      select @score;
      
      -- See the detail of model
      SELECT json_pretty(json_extract(model_explanation, "$.permutation_importance")) FROM ML_SCHEMA_admin.MODEL_CATALOG WHERE model_handle=@census_model;
      
      -- Specify 1 row example
      set @row_input = '{"age": 38,"workclass": "Private","fnlwgt": 89814,"education": "HS-grad","education-num": 9,"marital-status": "Married-civ-spouse","occupation": "Farming-fishing","relationship": "Husband","race": "White","sex": "Male","capital-gain": 0,"capital-loss": 0,"hours-per-week": 50,"native-country": "United-States"}' ;
      
      -- predict for 1 row
      SELECT json_pretty(sys.ML_PREDICT_ROW(@row_input, @census_model, NULL));
      
      -- explain for 1 row
      SELECT JSON_Pretty(sys.ML_EXPLAIN_ROW(@row_input, @census_model, JSON_OBJECT('prediction_explainer', 'permutation_importance')));
      
      -- predict for whole test table
      CALL sys.ML_PREDICT_TABLE('census.census_test', @census_model, 'census.census_test_predictions', NULL);
      
      -- explain for whole test table
      CALL sys.ML_EXPLAIN_TABLE('census.census_test', @census_model, 'census.census_test_explanations', JSON_OBJECT('prediction_explainer', 'permutation_importance'));
      
      -- unload model
      CALL sys.ML_MODEL_UNLOAD(@census_model);
      ```
- ONNX 구성 (python 기준)
  - install ONNX Runtime
    - pip install onnxruntime   ( GPU : pip install onnxruntime-gpu )
  - install ONNX per each model
    - pytorch   
      pip install torch
    - tensorflow    
      pip install tf2onnx
    - sklearn    
      pip install skl2onnx
  - export the model of sklearn into ONNX format
    ```
    from skl2onnx import convert_sklearn
    from skl2onnx.common.data_types import FloatTensorType

    initial_type = [('float_input', FloatTensorType([None, 4]))]
    onx = convert_sklearn(clr, initial_types=initial_type)
    with open("logreg_iris.onnx", "wb") as f:
      f.write(onx.SerializeToString())
    ```
  - import the model as ONNX type into HeatWave
    ```
    // 1. convert type into base64
    python -c "import onnx; import base64;
    open('iris_base64.onnx', 'wb').write(base64.b64encode(onnx.load('logreg_iris.onnx').SerializeToString()))"

    // 2. connect heatwave and then create temporary table for uploading the model
    mysql> CREATE TEMPORARY TABLE onnx_temp (onnx_string LONGTEXT);

    // 3. load the model data into the temporary table using "LOAD DATA INFILE" command in mysql
    mysql> LOAD DATA INFILE 'iris_base64.onnx'
           INTO TABLE onnx_temp
           CHARACTER SET binary
           FIELDS TERMINATED BY '\t'
           LINES TERMINATED BY '\r' (onnx_string);

    // 4. select the uploaded model from table into a session variable.
    mysql> SELECT onnx_string FROM onnx_temp INTO @onnx_encode;

    // 5. load the model into HeatWave using the above session variable.
    mysql> CALL sys.ML_MODEL_IMPORT(@onnx_encode, NULL, 'iris_onnx');
    ```
