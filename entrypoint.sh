#!/bin/bash -l

#inputs
token=$1
filename=$2
qbee_directory=$3
local_directory=$4
run=$5

echo -e "init token: $token\nfilename: $filename\nqbee_directory: $qbee_directory\nlocal_directory: $local_directory\nrun: $run"

if [ $run != 1 ]; then
    echo "run is set to false: all files up to date - not performing upload"
    exit 0
else
    echo "running file-upload-action for $filename"
fi

successful_status_code='200'

#get absolute path and add trailing slash
local_directory="$(cd $local_directory && pwd)/"

#make sure qbee_directory has both leading and trailing slash
[[ "${qbee_directory}" != /* ]] && qbee_directory="/${qbee_directory}"
[[ "${qbee_directory}" != */ ]] && qbee_directory="${qbee_directory}/"

apiOutput=$(curl --request "DELETE" -sL -d "path=$qbee_directory$filename" \
            -H "Content-type: application/x-www-form-urlencoded" \
            --url 'https://www.app.qbee.io/api/v2/file' \
            --header 'Authorization: Bearer '"$token" \
            -w "\n{\"http_code\":%{http_code}}\n")


echo 'DELETE request'
http_code=$(echo $apiOutput | jq -cs | jq -r '.[1].http_code')

echo "API output is:"
echo $apiOutput

if [ "$http_code" == "null" ]; then
    http_code=$(echo $apiOutput | jq -cs | jq -r '.[0].http_code')
else
    :
    #echo "http_code was not null"
fi

if [[ "$http_code" != "$successful_status_code" && "$http_code" != "400" && "$http_code" != "204" ]]; then
    echo "http_code was - $http_code"
    echo "something went wrong ... aborting"
    exit 1
elif [ "$http_code" == "400" ]; then
    echo "file not found ... not a problem ... continuing"
else
    echo "http_code was - $http_code"
fi

apiPostOutput=$(curl --request POST -sL -H "Content-Type:multipart/form-data" \
               -F "path=$qbee_directory" -F "file=@$local_directory$filename" \
               --url 'https://www.app.qbee.io/api/v2/file'\
               --header 'Authorization: Bearer '"$token"\
               -w "\n{\"http_code\":%{http_code}}\n")

echo 'POST request'
post_http_code=$(echo $apiPostOutput | jq -cs | jq -r '.[1].http_code')

echo "API Post output is:"
echo $apiPostOutput

if [ "$post_http_code" != "$successful_status_code" ]

then
    echo "http_code was - $post_http_code"
    echo "something went wrong ... aborting"
    exit 1
else
    echo "http_code was - $post_http_code"
fi
