#!/bin/bash

source .maintenance.config
source .env

display_usage() {
  echo "--backup for backup"
  echo "--update for update"
}

turn_on_maintainance() {
  echo "Turning on maintainance"
  docker exec --user www-data nextcloud_nextcloud_1 php occ maintenance:mode --on
}

turn_off_maintainance() {
  echo "Turning off maintainance"
  docker exec --user www-data nextcloud_nextcloud_1 php occ maintenance:mode --off
}

update() {
  # following
  # https://docs.nextcloud.com/server/18/admin_manual/maintenance/manual_upgrade.html
  # core
  cp "$BASE_FOLDER"/"$NEXTCLOUD_CORE"/.htaccess "$BASE_FOLDER"/update/
  cd "$BASE_FOLDER"/"$NEXTCLOUD_CORE"/
  rm -rvf ./*
  cd "$BASE_FOLDER"/update/nextcloud/
  cp -av ./* "$BASE_FOLDER"/"$NEXTCLOUD_CORE"/
  rm -rvf "$BASE_FOLDER"/"$NEXTCLOUD_CORE"/config/*
  cp -av "$BASE_FOLDER"/update/.htaccess "$BASE_FOLDER"/"$NEXTCLOUD_CORE"/
  chown -Rv www-data:www-data "$BASE_FOLDER"/"$NEXTCLOUD_CORE"/
  cd "$BASE_FOLDER"
  find "$BASE_FOLDER"/"$NEXTCLOUD_CORE"/ -type d -exec chmod 750 {} \;
  find "$BASE_FOLDER"/"$NEXTCLOUD_CORE"/ -type f -exec chmod 640 {} \;

}

backup() {
  # First backup while system is running to decrease time of downtime
  backup_internal
  # When this is done, put nextcloud in maintainance mode
  turn_on_maintainance
  # Now backup everything with maintainance mode on
  # this mode will make nextcloud not change any files or data.
  # Users will be not able to use nextcloud in this phase
  # This backup should be much faster
  backup_internal
  # we are also making a backup from the database
  backup_database
  # After everything has been backuped we can turn on the maintainance mode
  turn_off_maintainance
}

backup_database() {
  echo "hot backing up the database"
  docker exec -it nextcloud_mysql_1  \
            mysqldump -u root \
                      -p"$MYSQL_ROOT_PASSWORD" \
                      --single-transaction \
                      --routines \
                      --triggers \
                      nextcloud \
                      > $(realpath ${BACKUP_FOLDER})/${NEXTCLOUD_MYSQL}/nextcloud-dump.sql
  echo "done"
}

backup_internal() {
  rsync -av --delete $NEXTCLOUD_DATA_FOLDER ${BACKUP_FOLDER} || exit_with_message 1 "could not backup data"
  rsync -av --delete $(realpath ${BASE_FOLDER})/${LETSENCRYPT} $(realpath ${BACKUP_FOLDER}) || exit_with_message 2 "could not backup letsencrypt"
  rsync -av --delete $(realpath ${BASE_FOLDER})/${NEXTCLOUD_APPS} $(realpath ${BACKUP_FOLDER}) || exit_with_message 3 "could not backup apps"
  rsync -av --delete $(realpath ${BASE_FOLDER})/${NEXTCLOUD_CONFIG} $(realpath ${BACKUP_FOLDER}) || exit_with_message 4 "could not backup config"
  rsync -av --delete $(realpath ${BASE_FOLDER})/${NEXTCLOUD_CORE} $(realpath ${BACKUP_FOLDER}) || exit_with_message 5 "could not backup core"
  rsync -av --delete $(realpath ${BASE_FOLDER})/${NEXTCLOUD_MYSQL} $(realpath ${BACKUP_FOLDER}) || exit_with_message 6 "could not backup mysql"
}

exit_with_message() {
  EXIT_CODE=$1
  EXIT_MESSAGE=$2
  echo "$EXIT_MESSAGE"
  exit "$EXIT_CODE"
}

if [[ $# -lt 1 || "$1" = "-h" || "$1" = "--help" ]]; then
	display_usage
	exit 0
elif [[ "$1" = "--backup" ]]; then
  backup
elif [[ ""$1"" = "--update" ]]; then
  update
fi


