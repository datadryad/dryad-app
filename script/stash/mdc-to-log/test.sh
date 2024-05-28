#!/bin/bash
files=( counter_db_2018-06.sqlite3 counter_db_2018-07.sqlite3 \
counter_db_2018-08.sqlite3 \
counter_db_2018-09.sqlite3 \
counter_db_2018-10.sqlite3 \
counter_db_2018-11.sqlite3 \
counter_db_2018-12.sqlite3 \
counter_db_2019-01.sqlite3 \
counter_db_2019-02.sqlite3 \
counter_db_2019-03.sqlite3 \
counter_db_2019-04.sqlite3 \
counter_db_2019-05.sqlite3 \
counter_db_2019-06.sqlite3 \
counter_db_2019-07.sqlite3 )
for i in "${files[@]}"
do
  :
  echo $i
  ./main.rb $i
done
