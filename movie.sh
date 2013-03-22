#!/bing/bash
#testing change

for f in *.m4v; do mv "$f" "`basename "$f" `.mp4"; done;


#Change underscores to hypens
for f in *.mp4; do mv "$f" "`echo $f | sed "s/_/-/g"`"; done

#Remove Spaces From Files
for f in *.mp4; do mv "$f" "`echo $f | sed "s/ /-/g"`"; done

#Rename UPPERCASE to lowercase
for f in *.mp4; do mv "$f" `echo $f | tr ‘[:upper:]‘ ‘[:lower:]‘`; done

declare -a urls
declare -a files
for i in $(ls *.mp4 | cut -d. -f1); do 
	urls+=(`curl -iIs -A "Mozilla/5.0" "http://www.google.com/search?&q=site+www.imdb.com+$i&btnI" | grep "Location" | awk {'print $2'}`) && files+=($i);
done

declare -a titles
for i in "${urls[@]}"; do
# curl url| Grep for Movie Title | Cut to get movie title | Remove (date) -IMDb | Remove trailing space | make lower case | replace space to - | replace : to nothing			
	titles+=(`curl -s $i | grep "meta name=\"title\" content=\"" | cut -d\" -f4 | cut -d\( -f1 | sed "s/\(.*\)./\1/" | tr ‘[:upper:]‘ ‘[:lower:]‘ | sed "s/ /-/g" | sed "s/://g"`);
done

diff <(printf "%s\n" "${titles[@]}") <(printf "%s\n" "${files[@]}")

unset titles
unset urls
unset files
