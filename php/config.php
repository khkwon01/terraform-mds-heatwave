<?php
// Database credentials
define('DB_SERVER', '<<mds-ip>>');// MDS server IP address
define('DB_USERNAME', 'admin');
define('DB_PASSWORD', 'Welcome#1');
define('DB_NAME', 'census');
//Attempt to connect to MySQL database
$link = mysqli_connect(DB_SERVER, DB_USERNAME, DB_PASSWORD, DB_NAME);
// Check connection
if($link === false){
die('ERROR: Could not connect. ' . mysqli_connect_error());
}
// Print database connection result
// echo 'Successfull Connect.';
?>
