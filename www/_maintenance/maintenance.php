<?php
date_default_timezone_set('Europe/London');
header('HTTP/1.1 503 Service Temporarily Unavailable');
header('Status: 503 Service Temporarily Unavailable');
header('Retry-After: 3600');
header('Content-Type: text/html; charset=utf-8');
?>
<html>
  <head>

    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

    <title>Undergoing Maintenance</title>

    <style type="text/css">
    <!--
    body
    {
      font-family: Helvetica, Arial, Verdana, sans-serif;
      font-size: 18px;
      text-align: center;
    }
    h1, p
    {
      margin: 40px;
    }
    small
    {
      font-size: 14px;
    }
    -->
    </style>

  </head>
  <body>

    <!--<p><img src="/_maintenance/logo.png" alt="" width="" height="" /></p>-->
    <h1>Undergoing Maintenance</h1>
    <p>This website is currently being upgraded.</p>
    <p>Please check back soon.</p>
    <?php $file = $_SERVER['DOCUMENT_ROOT'] . '/../MAINTENANCE'; if (file_exists($file)) { ?>
        <p><small><em><?php echo date('D jS M Y, g:ia', filemtime($file)) ?></em></small></p>
    <?php } ?>

  </body>
</html>
