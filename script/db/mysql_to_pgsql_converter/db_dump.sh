#!/bin/sh
#
# Dump the mysql DBs, convert to Postgres, and do a little ad-hoc format munging.

main() {
   dump_and_convert kete3_development
   dump_and_convert kete3_test
   dump_and_convert kete3_production
}

dump_and_convert() {
   DB="$1"

   mysqldump --compatible=postgresql --hex-blob --default-character-set=utf8 -r "$DB.mysql" -u root -p "$DB"

   python db_converter.py "$DB.mysql" "$DB.pgsql"

   sed -i "" -e "s/(0x\([0-9A-F]*\)/(decode('\1','hex')/g" -e "s/,0x\([0-9A-F]*\)/,decode('\1','hex')/g" "$DB.pgsql"
   sed -i "" "s/ COLLATE utf8_unicode_ci//g" "$DB.pgsql"

   rm -f "$DB.mysql"
}


main
