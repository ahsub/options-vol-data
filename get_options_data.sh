#!/usr/bin/bash
echo "update,symbol,hv20,hv50,hv100,date,cur_iv,days_percentile,close" > data.csv \
&& curl -s https://www.optionstrategist.com/calculators/free-volatility-data \
| sed -n "/<pre/,/<\/pre>/p" \
| sed "s/<[^>]*>//g" \
| sed "/^\*/d" \
| sed "1,/^Symbol/d" \
| sed "s/\\([^/ *]\\)  */\\1,/g" \
| sed "/OPTION/d" \
| sed "s/%ile,*/%ile,/g" \
| awk -F, "NF==8" >> data.csv

# Assign today's date in yyyy-mm-dd format to a variable
DATE=$(date +%Y-%m-%d)

# Use awk to append the date to each line except the first one
awk -v d="$DATE" -F"," 'BEGIN {OFS = ","} NR>1 {$0=d","$0}1' data.csv > iv.csv

# remove temp data.csv file
rm data.csv

##=========== Anotated explanations of the script ==========

# echo "update,symbol,hv20,hv50,hv100,date,cur_iv,days_percentile,close" > data.csv \
# && curl -s https://www.optionstrategist.com/calculators/free-volatility-data \
# # Use sed to extract the text between <pre ...> and </pre> tags.
# # FIX (06.09.2026): changed pattern from "/<pre>/" (exact literal match,
# # requires the tag to have NO attributes) to "/<pre/" (matches "<pre"
# # as a prefix, regardless of any attributes). Root cause of the scraper
# # producing an empty iv.csv since ~03.08.2025: the source page now
# # renders the data block as <pre id="volContainer">...</pre> instead of
# # a bare <pre>...</pre> — the old exact-match pattern silently matched
# # zero lines, so every downstream step operated on empty input.
# # Verified by reproducing the bug against a reconstructed sample of the
# # live page's actual HTML (including the new nested <span class="vol-
# # header">/<span class="vol-line"> tags around each line) and confirming
# # this one-character change (dropping the trailing ">") restores correct
# # 8-field CSV output.
# | sed -n "/<pre/,/<\/pre>/p" \
# # Use sed to remove any HTML tags from the text
# | sed "s/<[^>]*>//g" \
# # Use sed to delete any lines that start with an asterisk
# | sed "/^\*/d" \
# # Use sed to delete the lines from the beginning until the line that starts with Symbol
# | sed "1,/^Symbol/d" \
# # Use sed to replace any sequence of spaces that is not preceded by a slash
# | sed "s/\\([^/ *]\\)  */\\1,/g" \
# # Use sed to delete any lines that contain OPTION
# | sed "/OPTION/d" \
# # Use sed to replace any occurrence of %ile followed by zero or more commas with %ile followed by one comma
# | sed "s/%ile,*/%ile,/g" \
# # Use awk to filter out any lines that do not have exactly eight fields separated by commas
# | awk -F, "NF==8" >> data.csv
