<?php
if(isset($_FILES['photo'])){
  move_uploaded_file($_FILES['photo']['tmp_name'], 'cam_' . time() . '.jpg');
}
?>
