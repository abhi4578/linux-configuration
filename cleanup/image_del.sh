#!/bin/bash
image_id=`docker images | grep "$1" | awk '{print $3}'`
image_list_id=`echo $image_id` 
for i in $image_list_id
do
	docker image rm $i 
done
