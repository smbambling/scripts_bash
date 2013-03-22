#!/bin/bash 

#Convert Headings
sed -i '' 's/h5./==/g' test.txt
sed -i '' '/==/s/$/==/g' test.txt

sed -i '' 's/h4./===/g' test.txt
sed -i '' '/===/s/$/===/g' test.txt

sed -i '' 's/h3./====/g' test.txt
sed -i '' '/====/s/$/====/g' test.txt

sed -i '' 's/h2./=====/g' test.txt
sed -i '' '/=====/s/$/=====/g' test.txt

sed -i '' 's/h1./======/g' test.txt
sed -i '' '/======/s/$/======/g' test.txt

#Replace Bold
sed -i '' -e 's/^*\([^*]\)/**\1/g' -e 's/\([^*#]\)\*/\1**/g' test.txt

#Replace Underline
sed -i '' -e 's/^_\([^_]\)/__\1/g' -e 's/ _\([^_]\)/ __\1/g' test.txt
sed -i '' -e 's/\([^_]\)_ *$/\1__/' -e 's/\([^_]\)_\( \{1,\}\)/\1__\2/g' test.txt

#Replace Code Lines
sed -i '' -e 's/{code} /<code> /g' -e 's/ {code}/ <\/code>/g' test.txt

cat<test.txt | $null
while read line
do
sed -i '' -e '1,/{code}/s/{code}/<code>/' test.txt
sed -i '' -e '1,/{code}/s/{code}/<\/code>/' test.txt
done < test.txt

#Replace Ordered Lists
sed -i '' -e 's/^# /  - /g' test.txt
sed -i '' -e 's/\#\* /    * /g' test.txt



