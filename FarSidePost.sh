#!/bin/bash

path="/home/ajorians/farside"
cd "$path"

flowusername="<Withheld>"
flowpassword="<Withheld>"

ftpurl="<Withheld>"

output=`date +"farside%y%m%d"`

postwalkiemessage () {
  #Replace double quotes with escaped ones such that I can do a REST post
   local message=$(echo $1|sed 's/\"/\\\"/g')

   local exactmessage="$message"

   local postdata="{\"event\":\"message\",\"external_user_name\":\"GaryLarson\",\"content\":\"$exactmessage\"}"

   local result=$(curl --header "Content-Type: application/json" \
     --request POST \
     --data "$postdata" \
     -u "$flowusername:$flowpassword" \
     https://api.flowdock.com/flows/$2/$3/messages)

   local id=$(echo $result | jq '.id')

   local emojipostdata="{\"type\": \"add\", \"emoji\": \"laughing\" }"

   curl --header "Content-Type: application/json" \
     --request POST \
     --data "$emojipostdata" \
     -u "$flowusername:$flowpassword" \
     https://api.flowdock.com/flows/$2/$3/messages/$id/emoji_reaction
}

whichone="$1"

outfn="${output}-${whichone}.jpg"
outfile="${path}/${outfn}"

outcap="${path}/${output}-${whichone}.txt"

if [ -n "$outfile" ]; then
   caption=`cat $outcap`
   comic="http://$ftpurl/a.orians/farside/$outfn"
   message="$comic $caption"
   postwalkiemessage "$message" "aj-org" "main"
else
   echo "No file downloaded :("
fi

