#!/bin/bash
# Watches for the incoming of new data.

while read path action file
do
    if [[ "$file" =~ .*zip$ ]]
    current=$(date +'%H:%M:%S %Y-%m-%d')
    then
        oldsize=0
        newsize=`size $path`
        while [ $oldsize != $newsize ]
        do
            oldsize=`size $path`
            sleep 1
            newsize=`size $path`
        done
        echo $file $current
        source /code/entrypoint.sh
    fi
done < <(inotifywait -mr /input -e create -e moved_to)