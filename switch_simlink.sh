#!/bin/bash -e

# Domain name
DOMAIN="example.com" 

# Project name
PROJECT="symfony/symfony-demo"

# Project version
PROJECT_VERSION=$1
# v1.6.4
# v1.8.0

# Directory that contains sources
SOURCE_DIR="${HOME}/src"

# Directory to deploy sources to
TARGET_DIR="/var/www/demo"

# Directory to keep old generations
STAGING_DIR="${HOME}/staging"

# Log file
LOG_FILE="${HOME}/log/deploy.log"

# Nginx config file
NG_CONF="${HOME}/symfony.conf"

function append_log () {
  if [ -d "$(dirname "$LOG_FILE")" ]; then
    tee -a "$LOG_FILE"
  else
    tee
  fi
}

function log_info () {
  echo "$(date --iso-8601=seconds) [deploy] $*" | append_log
}

function log_exec () {
  log_info "$@"
  "$@" 2>&1 | append_log
  if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    false
  fi
}


## Only once #################################################
#log_info "Disable apache server (only for current server)"
#log_exec sudo systemctl stop apache2.service
#log_exec sudo systemctl disable apache2.service
#######################################################

log_info "Deploying..."

log_info "Downloading dependencies.."
log_exec sudo apt-get update -y
log_exec sudo apt-get install -y git nginx mysql-server php7.4 libapache2-mod-php7.4 php7.4-common php7.4-gd php7.4-mysql php7.4-curl php7.4-intl php7.4-xsl php7.4-mbstring php7.4-zip php7.4-bcmath php7.4-soap php-xdebug php-sqlite3 php7.4-fpm

log_info "Downloading and installing composer"
log_exec php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
log_exec php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
log_exec php composer-setup.php
log_exec php -r "unlink('composer-setup.php');"
log_exec sudo mv composer.phar /usr/local/bin/composer


log_info "Creating dirs"
log_exec mkdir -vp "$SOURCE_DIR" "$STAGING_DIR"

log_info "Choosing the current version from stage"

# Current local version
LATEST_VERSION="$(ls "$STAGING_DIR" | sort -V | tail -1)"

log_info "The current version is $LATEST_VERSION"

if [ "${PROJECT_VERSION}" = "${LATEST_VERSION}" ] ; then
  log_info "Remove $SOURCE_DIR"
  log_exec sudo rm -rf "$SOURCE_DIR"
  log_info "The latest version is installed."
else
  log_info "Downloading symphony"
  log_exec composer create-project -n "${PROJECT}:${PROJECT_VERSION}" "${SOURCE_DIR}/${PROJECT_VERSION}" 
   
  log_info "Copying sources into $STAGING_DIR"
  log_exec sudo cp -aT "$SOURCE_DIR" "$STAGING_DIR"

  log_info "Remove $SOURCE_DIR"
  log_exec sudo rm -rf "$SOURCE_DIR"

  ###### Do restart nginx only first time ############################
  #log_info "Change nginx config file"
  #log_exec sed -i "s/{{ inventory_hostname }}/${DOMAIN}/g" $NG_CONF  
  
  #log_info "Replace nginx config file"
  #log_exec sudo cp -vaT $NG_CONF "/etc/nginx/sites-available/default"
  #log_exec sudo nginx -t
  #log_exec sudo systemctl restart nginx
  ####################################################################


  # Updated local version
  LATEST_VERSION="$(ls "$STAGING_DIR" | sort -V | tail -1)"
  
  log_info "Change owner for working directory"
  log_exec sudo chown -R "www-data:www-data" "${STAGING_DIR}/${LATEST_VERSION}"

  log_info "Updating symbolic link"
  log_exec sudo ln -vs "${STAGING_DIR}/${LATEST_VERSION}" "${TARGET_DIR}_tmp"
  log_exec sudo mv -vT "${TARGET_DIR}_tmp" "$TARGET_DIR"

  log_info "Removing old generations..."
  ls "$STAGING_DIR" | sort -V | head -n -2 | while read item; do
    log_exec sudo rm -fr "$STAGING_DIR/$item"
  done
  log_info "Successfully deployed"
fi
