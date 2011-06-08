<?php
include ('lib/config.php');
function isAllow($username){
	global $whiteList, $blackList, $accessControlMode;
	if(($accessControlMode == WHITELIST_MODE 
			&& !in_array($username, $whiteList))
		|| ($accessControlMode == BLACKLIST_MODE 
			&& in_array($username, $blackList))) {
		return false;
	}
	return true;
}

function sendDenyMessage($username){
	echo "<p>根据访问控制规则，" . $username . "被禁止使用，请返回。</p>";
}
?>