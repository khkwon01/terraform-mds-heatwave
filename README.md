# terraform-mds

Provision MySQL Database Service (MDS) and Heatwave with Terraform.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/khkwon01/terraform-mds/archive/refs/tags/mds-heatwave-v2.1.1.zip)


# Demo Cloud Architecture diagram
If you execute the above terraform code in oci, it make the below service like diagram which the heatwave node is disabled.
<img width="802" alt="image" src="https://user-images.githubusercontent.com/8789421/213102145-3a14870d-7a6a-4a54-a1fb-d2eee02c4d58.png">

# Demo scenario
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
      DROP DATABASE IF EXISTS census;
      CREATE DATABASE census;
      USE census;

      CREATE TABLE census_train ( age INT, workclass VARCHAR(255), fnlwgt INT, education VARCHAR(255), `education-num` INT, `marital-status` VARCHAR(255), occupation VARCHAR(255), relationship VARCHAR(255), race VARCHAR(255), sex VARCHAR(255), `capital-gain` INT, `capital-loss` INT, `hours-per-week` INT, `native-country` VARCHAR(255), revenue VARCHAR(255));
      CREATE TABLE census_test LIKE census_train;
      ``` 
    - 데이터 import
      ```
      mysqlsh admin@<your ip> --mc    # class mode
      \js
      util.importTable("census_train.csv",{table: "census_train", dialect: "csv-unix", skipRows:1})
      util.importTable("census_test.csv",{table: "census_test", dialect: "csv-unix", skipRows:1})
      ```
    - ML 
      ```
      \sql
      -- Train the model
      CALL sys.ML_TRAIN('census.census_train', 'revenue', JSON_OBJECT('task', 'classification'), @census_model);
      -- Load the model into HeatWave
      CALL sys.ML_MODEL_LOAD(@census_model, NULL);
      -- Score the model on the test data
      CALL sys.ML_SCORE('census.census_test', 'revenue', @census_model, 'balanced_accuracy', @score);
      -- Select score
      select @score;
      -- See the detail of model
      SELECT model_explanation FROM ML_SCHEMA_admin.MODEL_CATALOG WHERE model_handle=@census_model;
      -- Specify 1 row example
      set @row_input = '{"index": 1,"age": 38,"workclass": "Private","fnlwgt": 89814,"education": "HS-grad","education-num": 9,"marital-status": "Married-civ-spouse","occupation": "Farming-fishing","relationship": "Husband","race": "White","sex": "Male","capital-gain": 0,"capital-loss": 0,"hours-per-week": 50,"native-country": "United-States"}' ;
      -- predict for 1 row
      SELECT sys.ML_PREDICT_ROW(@row_input, @census_model, NULL);
      -- explain for 1 row
      SELECT sys.ML_EXPLAIN_ROW(@row_input, @census_model, JSON_OBJECT('prediction_explainer', 'permutation_importance'));
      -- predict for whole test table
      CALL sys.ML_PREDICT_TABLE('census.census_test', @census_model, 'census.census_test_predictions', NULL);
      -- explain for whole test table
      CALL sys.ML_EXPLAIN_TABLE('census.census_test', @census_model, 'census.census_test_predictions', JSON_OBJECT('prediction_explainer', 'permutation_importance'));
      -- unload model
      CALL sys.ML_MODEL_UNLOAD(@census_model);
      ```
