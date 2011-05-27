<?php
define('SITE_NAME', '##SITE_NAME##');
define('SECURE_KEY', '##SECURE_KEY##');
define('OAUTH_KEY','##OAUTH_KEY##');
define('OAUTH_SECRET','##OAUTH_SECRET##');
define('BASE_URL','##BASE_URL##');
define('API_URL', 'http://api.twitter.com/1');
define('TWITESE_API_URL', 'http://twiteseapi.appspot.com');
define('TWITESE_PASSWORD', '');
define('VISITOR_ALLOW', false);
define('WHITELIST_MODE', 0);
define('BLACKLIST_MODE', 1);
define('NOCONTROL_MODE', 2);
define('API_VERSION','1');
define('DEBUG',FALSE);
define('DOLOG',FALSE);
define('COMPRESS',TRUE);
$accessControlMode = NOCONTROL_MODE;
$blackList = array("##BLACKLIST##");
$whiteList = array("##WHITELIST##");
?>
