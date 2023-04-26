<?php
  require_once "config.php";

  // Check connection
  if($link === false){
    die("ERROR: Could not connect. " . mysqli_connect_error());
  }

  $err_dis = "";
  $census_model = $row_input = $predict = "";
  $age = $workclass = $fnlwgt = $education = $educationnum = $maritalstatus = "";
  $occupation = $relationship = $race = $sex = $capitalgain = $capitalloss = "";
  $hourspw = $native = "";

  if ($_SERVER["REQUEST_METHOD"] == "POST") {

    //echo "<script>alert('{$_POST["capitalgain"]}');</script>";
    if (empty($_POST["age"])) {
      $err_dis = "age,";
    } else {
      $age = test_input($_POST["age"]);
    }
    if (empty($_POST["workclass"])) {
      $err_dis .= " workclass,";
    } else {
      $workclass = test_input($_POST["workclass"]);
    }	    
    if (empty($_POST["fnlwgt"])) {
      $err_dis = "fnlwgt,";
    } else {
      $fnlwgt = test_input($_POST["fnlwgt"]);
    }
    if (empty($_POST["education"])) {
      $err_dis .= " education,";
    } else {
      $education = test_input($_POST["education"]);
    }
    if ($_POST["educationnum"] == "") {
      $err_dis .= " educationnum,";
    } else {
      $educationnum = test_input($_POST["educationnum"]);
    }    
    if (empty($_POST["maritalstatus"])) {
      $err_dis .= " maritalstatus,";
    } else {
      $maritalstatus = test_input($_POST["maritalstatus"]);
    }
    if (empty($_POST["occupation"])) {
      $err_dis .= " occupation,";
    } else {
      $occupation = test_input($_POST["occupation"]);
    }
    if (empty($_POST["relationship"])) {
      $err_dis .= " relationship,";
    } else {
      $relationship = test_input($_POST["relationship"]);
    }
    if (empty($_POST["race"])) {
      $err_dis .= " race,";
    } else {
      $race = test_input($_POST["race"]);
    }
    if (empty($_POST["sex"])) {
      $err_dis .= " sex,";
    } else {
      $sex = test_input($_POST["sex"]);
    }
    if ($_POST["capitalgain"] == "") {
      $err_dis .= " capitalgain,";
    } else {
      $capitalgain = test_input($_POST["capitalgain"]);
    }
    if ($_POST["capitalloss"] == "") {
      $err_dis .= " capitalloss,";
    } else {
      $capitalloss = test_input($_POST["capitalloss"]);
    }
    if ($_POST["hourspw"] == "") {
      $err_dis .= " hourspw,";
    } else {
      $hourspw = test_input($_POST["hourspw"]);
    }
    if (empty($_POST["native"])) {
      $err_dis .= " native,";
    } else {
      $native = test_input($_POST["native"]);
    }
    
    if (strlen($err_dis) > 1) { 
      $err_dis = trim($err_dis, ",");
      $err_dis .= " 필수입력항목입니다.";
    }
  }

  function test_input($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
  }

  function load_model($link) {
    $query = "SET @census_model = (SELECT model_handle FROM ML_SCHEMA_admin.MODEL_CATALOG ORDER BY model_id DESC LIMIT 1);";
    $stmt = $link->prepare($query);
    $stmt->execute();
    $stmt->close();

    $query = "CALL sys.ML_MODEL_LOAD(@census_model, NULL);";
    $stmt = $link->prepare($query);
    $stmt->execute(); 
    $stmt->close();
  }

  function use_model($link,$census_model,$age,$workclass,$fnlwgt,$education,$educationnum,$maritalstatus,$occupation,$relationship,$race,$sex,$capitalgain,$capitalloss,$hourspw,$native) {
    //echo "<script>alert('{$age}');</script>";
    $query = "SET @row_input = JSON_OBJECT( 
	         'age', $age, 'workclass', '$workclass', 'fnlwgt', $fnlwgt,
		 'education', '$education', 'education-num', $educationnum,
		 'marital-status', '$maritalstatus', 'occupation', '$occupation',
		 'relationship', '$relationship', 'race', '$race', 'sex', '$sex', 
		 'capital-gain', $capitalgain, 'capital-loss', $capitalloss,
		 'hours-per-week', $hourspw, 'native-country', '$native'
	      );";
    $stmt = $link->prepare($query);
    $stmt->execute();
    $stmt->close();

    $query = "SELECT sys.ML_PREDICT_ROW(@row_input, @census_model, NULL);";
    $stmt = $link->prepare($query);
    $stmt->execute();
    $stmt->bind_result($pred_out);
    $stmt->fetch();
    $predict= $pred_out;
    $stmt->close();	  

    $query = "SELECT sys.ML_EXPLAIN_ROW(@row_input, @census_model, JSON_OBJECT('prediction_explainer', 'permutation_importance'));";
    $stmt = $link->prepare($query);
    $stmt->execute();
    $stmt->bind_result($explain);
    $stmt->fetch();
    $stmt->close();    

    $query = "CALL sys.ML_MODEL_UNLOAD(@census_model);";
    $stmt = $link->prepare($query);
    $stmt->execute();
    $stmt->close();

    show_output($predict,$explain);

  } 

  function show_output($predict,$explain) {
    $prdobj = json_decode($predict);
    $expobj = json_decode($explain);

    //echo "<script>alert('{$prd}');</script>";
    echo '<pre>';
    echo "\n";
      echo "<h3>Based on the feature inputs that were provided, the model predicts for each census: </h3>";
        echo "<table>";
          echo "<tr>";
            echo "<td>Predict Value: </td>";
            echo "<td><b>";
              echo $prdobj->{'Prediction'} ;
            echo "</td>";
          echo "</tr>";
          echo "<tr>";
	    echo "<td>Predict Detail: </td>";
	    echo "<td>";
              echo $prdobj->{'ml_results'} ;
            echo "</td>";
	  echo "</tr>";
	  echo "<tr>" ;
            echo "<td>Explanation: </td>" ;
	    echo "<td>";
              echo $expobj->{'ml_results'} ;
	    echo "</td>";
	  echo "</tr>" ;
        echo "</table>";
    echo '</pre>';
  }
?>

<!DOCTYPE HTML>  
  <html>
  <head>
  <style>
    .error {color: #FF0000;}
    th {
      text-align: left;
      width: 300px;
    }
  </style>
  </head>
  <body>  
  <h2>Machine Learning Demo - Task classification using the census Dataset </h2>
  <img class="img-responsive" src="images/Census-bureau.png" alt="census_dataset" window=1000 height=400> 
  <h4>Example:</h4>
  <?php
  echo '<pre>';
  echo '<p><font color=blue>revenue<=50K -> </font>age: 38, workclass: Private, fnlwgt: 215646, education: HS-grad, education-num: 9,</p>';
  echo '                marital-status: Divorced, occupation: Handlers-cleaners, relationship: Not-in-family, race: White, sex: Male,</p>';
  echo '                capital-gain: 0, capital-loss: 0, hours-per-week: 40, native-country: United-States</p>';
  echo '<p><font color=blue>revenue>50K  -> </font>age: 31, workclass: Private, fnlwgt: 45781, education: Masters, education-num: 14,</p>';
  echo '                marital-status: Never-married, occupation: Prof-specialty, relationship: Not-in-family, race: White, sex: Female,</p>';
  echo '                capital-gain: 14084, capital-loss: 0, hours-per-week: 50, native-country: United-States</p>';
  echo '</pre>';
  ?>
  <h3>Enter the following information:</h3>

  <p><span class="error">* required field : <?php echo $err_dis;?></span></p>
  <form method="post" action="<?php $_SERVER["PHP_SELF"];?>"> 
    <table>
    <tr>
    <th><span style="padding-left: 2px;"> age: <span style="padding-left: 2px;"> <input type="number" min="1" max="100" step="1" name="age" value="<?php echo $age;?>" > </th>
    <th><span style="padding-left: 2px;"> workclass: <span style="padding-left: 8px;"> <input type="text" name="workclass" value="<?php echo $workclass;?>"></th>
    </tr>
    <tr>
    <th><span style="padding-left: 2px;"> fnlwgt: <span style="padding-left: 6px;"> <input type="number" min="0" max="10000000" step="0.1" name="fnlwgt" value="<?php echo $fnlwgt;?>"></th>
    <th><span style="padding-left: 2px;"> education: <span style="padding-left: 10px;"> <input type="text" name="education" value="<?php echo $education;?>"></th>
    </tr>
    <tr>
    <th><span style="padding-left: 2px;"> education-num: <span style="padding-left: 10px;"> <input type="number" min="0" max="100" step="1" name="educationnum" value="<?php echo $educationnum;?>"></th>
    <th><span style="padding-left: 2px;"> marital-status: <span style="padding-left: 10px;"> <input type="text" name="maritalstatus" value="<?php echo $maritalstatus;?>"></th>
    </tr>
    <tr>
    <th><span style="padding-left: 2px;"> occupation: <span style="padding-left: 10px;"> <input type="text" name="occupation" value="<?php echo $occupation;?>"></th>
    <th><span style="padding-left: 2px;"> relationship: <span style="padding-left: 10px;"> <input type="text" name="relationship" value="<?php echo $relationship;?>"></th>
    </tr>
    <tr>
    <th><span style="padding-left: 2px;"> race: <span style="padding-left: 10px;"> <input type="text" name="race" value="<?php echo $race;?>"></th>
    <th><span style="padding-left: 2px;"> sex: <span style="padding-left: 10px;"> 
    <select name="sex">
        <option value="">--plz select a gender--</option>
        <option value="Male">Male</option>
        <option value="Female">Female</option>
    </select></th>
    </tr>
    <tr>
    <th><span style="padding-left: 2px;"> capital-gain: <span style="padding-left: 10px;"> <input type="number" min="0" max="100000000" step="0.1" name="capitalgain" value="<?php echo $capitalgain;?>"></th>
    <th><span style="padding-left: 2px;"> capital-loss: <span style="padding-left: 10px;"> <input type="number" max="100000000" step="0.1" name="capitalloss" value="<?php echo $capitalloss;?>"></th>
    </tr>
    <tr>
    <th><span style="padding-left: 2px;"> hours-per-week: <span style="padding-left: 10px;"> <input type="number" min="0" max="1000" step="0.1" name="hourspw" value="<?php echo $hourspw;?>"></th>
    <th><span style="padding-left: 2px;"> native-country: <span style="padding-left: 10px;"> <input type="text" name="native" value="<?php echo $native;?>"></th>
    </tr>
    <tr><th style="text-align:center" colspan=2><input type="submit" name="submit" value="Submit"></th></tr>  
    </table>
  </form>
  <?php

    if($age !="" && $workclass !="" && $fnlwgt !="" && $education !="" &&
       $educationnum !="" && $maritalstatus !="" && $occupation !="" && $relationship !="" &&
       $race !="" && $sex !="" && $capitalgain !="" && $capitalloss !="" && $hourspw !="" && $native !="")
    {
      $census_model = load_model($link); 
      use_model($link,$census_model,$age,$workclass,$fnlwgt,$education,$educationnum,$maritalstatus,$occupation,$relationship,$race,$sex,$capitalgain,$capitalloss,$hourspw,$native);
    }
  ?> 
</body>
</html>
