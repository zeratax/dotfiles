#!/usr/bin/env bash
# jii.moe uploader
# requires: curl, jshon
# WTFPL - leg@national.shitposting.agency
#
# Only the file link is output to stdin, do you can pipe it
# to other tools, like $ jii somefile.jpg | xclip
#
# Upload: $ jii somefile.jpg
# Delete: $ jii --delete E1OLWAWF/X1wn4kOu5Kgw1auk

endpoint="https://jii.moe/api/v1/upload"

err() {
    echo 1>&2 "$@"
}

# delete file
if [ "$1" == "--delete" ]
then
    shift
    for file in "$@"
    do
        # send the HTTP DELETE
        response=$(curl --silent -X DELETE https://jii.moe/api/v1/upload/$file)
    done

# upload file
elif [ -n "$1" ]
then
    for file in "$@"
    do
        if [ ! -f $file ]
        then
            err "$file: Does not exist"
            continue
        fi

        # send the HTTP POST
        response=$(curl -# --fail --form "file=@${file}" https://jii.moe/api/v1/upload)
        err
        status=$?

        if [ $status == 0 ]
        then
            # print the URL
            echo $(echo $response | jshon -e url -u)

            # print the removal hash to stderr
            err -n $(echo $response | jshon -e _id -u)/
            err $(echo $response | jshon -e metadata -e deleteHash -u)
        else
            # error ocurred
            echo "An error ocurred"
            exit 1
        fi
    done

# print usage
else
    cmd=$(basename "$0")
    err "usage: $cmd [file ...]"
    err "       $cmd --delete [id/hash ...]"
fi
