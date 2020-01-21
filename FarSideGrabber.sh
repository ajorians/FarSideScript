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

      if [[ $section =~ $regexCaption ]]
      then
         echo "Match caption :)"
         echo "${BASH_REMATCH[1]}"

         local caption=${BASH_REMATCH[1]}
         section=${section##*${BASH_REMATCH[1]}}

         curl -T "$fullpath" "ftp://$ftpurl/a.orians/farside/" --user $ftpusername:$ftppassword --retry 10 --retry-delay 5

         echo "$caption" > "$outcap"
      else
         echo "No match caption :("
      fi
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

      if [ $count -gt -lt 10 ]; then
         echo "More comics than expected; exiting"
         exit 1
      fi
   done

else
   echo "No file downloaded :("
fi

