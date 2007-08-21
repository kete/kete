#!/bin/sh
#
# zebradb/zebrasrv-kill.sh
#
# for stopping parent zebrasrv and its children

pid_file=$1
parent_pid=`cat $pid_file`


for child in $(ps -o pid,ppid -ax | \
   awk "{ if ( \$2 == $parent_pid ) { print \$1 }}")
do
  echo "Killing child process $child because ppid = $parent_pid"
  kill $child
done

kill $parent_pid

# clean passed in pid file path
rm $pid_file
