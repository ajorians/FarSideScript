#!/bin/bash

path="/home/ajorians/farside"

ftpusername=<Withheld>
ftppassword=<Withheld>
ftpurl=<Withheld>

cd "$path"

file="output.htm"
nonewlines="nonewlines.htm"
output=`date +"farside%y%m%d"`

rm "$file"
rm "$nonewlines"

url="https://www.thefarside.com"
#echo $url
wget --user-agent="User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12" "$url" -O "$file"

regexComic='<div class="card tfs-comic js-comic">(.|\n)+?class="card-footer'
regexImg='(https://assets.amuniversal.com/[^"]*)"'
regexCaption='<figcaption[^>]*>\s*([^<]*)</figcaption'

SaveComicAndCaption () {
   local section=$1
   local part=$2

   local outfn="${output}-${part}.jpg"
   local outcap="${output}-${part}.txt"

   if [[ $section =~ $regexImg ]]
   then
      echo "Match :)"
      echo "${BASH_REMATCH[1]}"

      wget "${BASH_REMATCH[1]}" -O "$outfn"

      local fullpath="${path}/$outfn"

      ## Save caption if there is one
      if [[ $section =~ $regexCaption ]]
      then
         echo "Match caption :)"
         echo "${BASH_REMATCH[1]}"

         local caption=${BASH_REMATCH[1]}
         section=${section##*${BASH_REMATCH[1]}}

         echo "$caption" > "$outcap"
      else
         echo "No match caption :("
      fi

      # Upload the file via FTP
      for I in 1 2 3
      do
         curl -T "$fullpath" "ftp://$ftpurl" --user $ftpusername:$ftppassword --retry 10 --retry-delay 5
         sleep 10

         local uploadres=`curl -I http://$ftpurl/$outfn`

         if [[ $uploadres == *"200 OK"* ]]; then
            echo "File is there :)"
            break;
         else
            echo "File is not there :("
         fi
      done
   fi
}


if [ -n "$file" ]; then
   htmlcontent=`cat $file`
   tr -d '\n' < $file > $nonewlines
   sed -i "s/<i>/*/g" $nonewlines
   sed -i "s/<\/i>/*/g" $nonewlines
   sed -i "s/<b>/*/g" $nonewlines
   sed -i "s/<\/b>/*/g" $nonewlines
   sed -i "s/<u>/*/g" $nonewlines
   sed -i "s/<\/u>/*/g" $nonewlines

   reducedcontent=`cat $nonewlines`

   echo "Finding the comics"

   count=0
   grep -Po "<div class=\"card tfs-comic js-comic\">(.|\n)+?class=\"card-footer" <<< "$reducedcontent" | while read -r line; do
      SaveComicAndCaption "$line" $count
      count=$((count+1))

      if [ $count -gt 10 ]; then
         echo "More comics than expected; exiting"
         exit 1
      fi
   done

else
   echo "No file downloaded :("
fi

