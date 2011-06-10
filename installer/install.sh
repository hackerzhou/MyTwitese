#!/bin/sh

CONFIG_FILE="./config.cfg"
ALLOW_NO_SSL=1

prompt()
{
  echo "\033[1;32m$1\033[0m"
}

error()
{
  echo "\033[1;31m$1\033[0m"
}

print()
{
  echo "\033[1;34m$1\033[0m"
}

input_string_filter()
{
  TEMP=$(echo $1 | sed -e "s/'/\\\'/g")
  TEMP=$(echo $TEMP | sed -e 's/\"/\\\"/g')
}

print_config()
{
  print "======================================"
  print "==    Installation Configuration    =="
  print "======================================"
  echo "INSTALL_DIR = $INSTALL_DIR"
  echo "TWITESE_WEB_URL = $TWITESE_WEB_URL"
  echo "APACHE_USER = $APACHE_USER"
  echo "REWRITE_BASE = $REWRITE_BASE"
  echo "OAUTH_KEY = $OAUTH_KEY"
  echo "OAUTH_SECRET = $OAUTH_SECRET"
  echo "SITE_NAME = $SITE_NAME"
  echo "SECURE_KEY = $SECURE_KEY"
  echo "ACL_MODE = $ACL_MODE"
  echo "WHITELIST = $WHITELIST"
  echo "BLACKLIST = $BLACKLIST"
}

check_web_url()
{
  MATCH=$(echo "$TWITESE_WEB_URL" | grep -E "^https://[^\s]+")
  if [ $ALLOW_NO_SSL -eq 0 ]; then
    if [ -z $MATCH ]; then
      error "Error: URL must start with \"https://\" to anti-GFW!"
      return 1
    fi
  fi
  MATCH=$(echo "$TWITESE_WEB_URL" | grep -E "/$")
  if [ -z $MATCH ]; then
    TWITESE_WEB_URL="$TWITESE_WEB_URL/"
  fi
  REWRITE_BASE=${TWITESE_WEB_URL#*//*/}
  REWRITE_BASE="/$REWRITE_BASE"
  return 0
}

check_install_dir()
{
  MATCH=$(echo "$INSTALL_DIR" | grep -E "/$")
  if [ -n "$MATCH" ]; then
    INSTALL_DIR=${INSTALL_DIR%/*}
  fi
}

config_acl()
{
  prompt "Config $1 ACL rules"
  ACL_TEMP=""
  until [ -z "$INPUT" -a -n "$TEMP" ]
  do
    prompt "Add a twitter id to the $1 (Press enter to finish adding) :"
    read INPUT
    if [ -n "$INPUT" ]; then
      input_string_filter "$INPUT"
      INPUT=$TEMP
      INPUT="\\\"$INPUT\\\""
      if [ -z "$ACL_TEMP" ]; then
        ACL_TEMP="$INPUT"
      else
        ACL_TEMP="$ACL_TEMP, $INPUT"
      fi
    fi
  done
  case $1 in
    "whitelist")
      WHITELIST=$ACL_TEMP;;
    "blacklist")
      BLACKLIST=$ACL_TEMP;;
  esac
}

get_user_config()
{
  until [ -n "$INSTALL_DIR" ]
  do
    prompt "Please input the install folder :"
    read -r INSTALL_DIR
  done
  check_install_dir
  RET=1
  until [ -n "$TWITESE_WEB_URL" -a $RET -eq 0 ]
  do
    prompt "Please input the twitese's install url :"
    read -r TWITESE_WEB_URL
    if [ -n "$TWITESE_WEB_URL" ]; then
      check_web_url
      RET=$?
    fi
  done
  prompt "Please input the apache's running user (default www-data) :"
  read -r APACHE_USER
  if [ -z "$APACHE_USER" ]; then
    APACHE_USER="www-data"
  fi
  until [ -n "$OAUTH_KEY" ]
  do
    prompt "Please input your OAuth consumer key :"
    print "(If haven't, visit http://twitter.com/apps/new to register.)"
    read OAUTH_KEY
  done
  until [ -n "$OAUTH_SECRET" ]
  do
    prompt "Please input your OAuth consumer secret :"
    read OAUTH_SECRET
  done
  until [ -n "$SITE_NAME" ]
  do
    prompt "Please input your MyTwitese site name :"
    read -r SITE_NAME
  done
  SECURE_KEY=$(awk 'BEGIN{srand();print a=int(100000000*rand())}')
  prompt "Please select ACL mode (b for BlackList, w for WhiteList, default NoControl)"
  read ACL_MODE
  case $ACL_MODE in
    "b")
      ACL_MODE="BLACKLIST_MODE"
      config_acl "blacklist";;
    "w")
      ACL_MODE="WHITELIST_MODE"
      config_acl "whitelist";;
    *)
      ACL_MODE="NOCONTROL_MODE";;
  esac

  input_string_filter "$INSTALL_DIR"
  INSTALL_DIR=$TEMP
  input_string_filter "$APACHE_USER"
  APACHE_USER=$TEMP
  input_string_filter "$TWITESE_WEB_URL"
  TWITESE_WEB_URL=$TEMP
  input_string_filter "$REWRITE_BASE"
  REWRITE_BASE=$TEMP
  input_string_filter "$OAUTH_KEY"
  OAUTH_KEY=$TEMP
  input_string_filter "$OAUTH_SECRET"
  OAUTH_SECRET=$TEMP
  input_string_filter "$SITE_NAME"
  SITE_NAME=$TEMP
  
  echo "INSTALL_DIR=\"$INSTALL_DIR\"" > $CONFIG_FILE
  echo "APACHE_USER=\"$APACHE_USER\"" >> $CONFIG_FILE
  echo "TWITESE_WEB_URL=\"$TWITESE_WEB_URL\"" >> $CONFIG_FILE
  echo "REWRITE_BASE=\"$REWRITE_BASE\"" >> $CONFIG_FILE
  echo "OAUTH_KEY=\"$OAUTH_KEY\"" >> $CONFIG_FILE
  echo "OAUTH_SECRET=\"$OAUTH_SECRET\"" >> $CONFIG_FILE
  echo "SITE_NAME=\"$SITE_NAME\"" >> $CONFIG_FILE
  echo "SECURE_KEY=\"$SECURE_KEY\"" >> $CONFIG_FILE
  echo "ACL_MODE=\"$ACL_MODE\"" >> $CONFIG_FILE
  echo "WHITELIST=\"$WHITELIST\"" >> $CONFIG_FILE
  echo "BLACKLIST=\"$BLACKLIST\"" >> $CONFIG_FILE
  echo "\n" >> $CONFIG_FILE
}

install_mytwitese()
{
  if [ "$1" = "fromCurrentDir" ]; then
    print "\n## Install from current dir (for develop & debug) ##"
  else
    print "\n## Download and install ##"
  fi
  
  print "=> Check and creating folders ..."
  if [ ! -d $INSTALL_DIR ]; then
    mkdir -p $INSTALL_DIR
  fi
  if [ ! -d $INSTALL_DIR ]; then
    echo "Error: Cannot create folder $INSTALL_DIR!"
    exit 1;
  fi
  if [ "$1" = "fromCurrentDir" ]; then
    print "=> Copying files from current dir to install dir ..."
    cp -rRp -f ../. $INSTALL_DIR/
    cp -R -f ../.htaccess $INSTALL_DIR/
  else
    print "=> Downloading latest release ..."
    wget --no-check-certificate https://github.com/hackerzhou/MyTwitese/zipball/master -O MyTwitese.zip --timeout=30 -q
    if [ ! -f MyTwitese.zip ]; then
      error "Error: Cannot download MyTwitese!"
      exit 1;
    fi
    print "=> Unzipping files ..."
    unzip -o MyTwitese.zip -d $INSTALL_DIR/ > /dev/null
    cp -rRp -f $INSTALL_DIR/hackerzhou-MyTwitese-*/. $INSTALL_DIR/
    cp -R -f $INSTALL_DIR/hackerzhou-MyTwitese-*/.htaccess $INSTALL_DIR/
    rm -R $INSTALL_DIR/hackerzhou-MyTwitese-*/
    rm MyTwitese.zip
  fi
  print "=> Changing file mode and owner ..."
  chmod 755 -R $INSTALL_DIR/
  chown $APACHE_USER:$APACHE_USER -R $INSTALL_DIR/
}

config_mytwitese()
{
  print "\n## Write config file ##"
  CONFIG_FILE=$INSTALL_DIR/lib/config.php
  print "=> Writing $CONFIG_FILE ..."
  BASE_URL="${TWITESE_WEB_URL}api/"
  cp -f $INSTALL_DIR/lib/config_example.php $CONFIG_FILE
  SITE_NAME=$(echo $SITE_NAME | sed "s/\\\\/\\\\\\\\/g")
  BASE_URL=$(echo $BASE_URL | sed "s:\/:\\\/:g")
  sed -i "s/##SITE_NAME##/$SITE_NAME/g" $CONFIG_FILE
  sed -i "s/##SECURE_KEY##/$SECURE_KEY/g" $CONFIG_FILE
  sed -i "s/##OAUTH_KEY##/$OAUTH_KEY/g" $CONFIG_FILE
  sed -i "s/##OAUTH_SECRET##/$OAUTH_SECRET/g" $CONFIG_FILE
  sed -i "s/##BASE_URL##/$BASE_URL/g" $CONFIG_FILE
  sed -i "s/\ =\ NOCONTROL_MODE/\ =\ $ACL_MODE/g" $CONFIG_FILE
  sed -i "s/\"##BLACKLIST##\"/$BLACKLIST/g" $CONFIG_FILE
  sed -i "s/\"##WHITELIST##\"/$WHITELIST/g" $CONFIG_FILE
  HTACCESS_FILE=$INSTALL_DIR/.htaccess
  print "=> Writing $HTACCESS_FILE ..."
  REWRITE_BASE=$(echo $REWRITE_BASE | sed "s:\/:\\\/:g")
  sed -i "s/RewriteBase.*/RewriteBase\ $REWRITE_BASE/g" $HTACCESS_FILE
}

print "############################################################"
print "## Welcome use hackerzhou's MyTwitese installation script ##"
print "############################################################\n"

#Check whether the script is running in root privilege
if [ ! $USER = "root" ]; then
  error "Error: This script must be excuted in root privilege!"
  error "Please use sudo install.sh to run this script."
  exit 1;
fi

MATCH=$(echo "$@" | grep "\-\-help")
if [ -n "$MATCH" ]; then
  print "Usage: install.sh (--reconfig|--cleanInstallDir|--help|--fromCurrentDir)"
  print "  reconfig will lose your previous configuration."
  print "  cleanInstallDir will remove all files but oauth in installdir."
  print "  fromCurrentDir will install MyTwitese from current dir."
  print "  If no parameter, script will automatically install/upgrade.\n"
  exit 0
fi

MATCH=$(echo "$@" | grep "\-\-reconfig")
if [ -n "$MATCH" ]; then
  #Remove config file if run with "install.sh reconfig"
  rm -f $CONFIG_FILE
fi

#Load config file if exists
if [ -f $CONFIG_FILE -a -r $CONFIG_FILE ]; then
  . $CONFIG_FILE
fi

#If config not valid, need user to do configuration
if [ -z "$INSTALL_DIR" -a -z "$APACHE_USER" -a -z "$TWITESE_WEB_URL" ]; then
  get_user_config
fi

MATCH=$(echo "$@" | grep "\-\-cleanInstallDir")
if [ -n "$MATCH" ]; then
  #backup api/oauth folder and remove install dir
  if [ -d $INSTALL_DIR/api/oauth/ ]; then
    cp -f -R $INSTALL_DIR/api/oauth/ ./
  fi
  rm -f -R $INSTALL_DIR
  if [ -d ./oauth/ ]; then
    mkdir -p $INSTALL_DIR/api/oauth/
    cp -R -f ./oauth/* $INSTALL_DIR/api/oauth/
    rm -R -f ./oauth/
  fi
fi

#Print configuration
print_config

#Download and install mytwitese
MATCH=$(echo "$@" | grep "\-\-fromCurrentDir")
if [ -n "$MATCH" ]; then
  install_mytwitese "fromCurrentDir"
else
  install_mytwitese
fi

#Config mytwitese
config_mytwitese

print "\nDone successfully!"
