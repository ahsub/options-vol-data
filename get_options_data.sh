#!/usr/bin/bash
echo "update,symbol,hv20,hv50,hv100,date,cur_iv,days_percentile,close" > data.csv \
&& curl -s https://www.optionstrategist.com/calculators/free-volatility-data \
| sed -n "/<pre/,/<\/pre>/p" \
| sed "s/<[^>]*>//g" \
| sed "/^\*/d" \
| awk '/^Symbol/{last=NR} {line[NR]=$0} END{for(i=last+1;i<=NR;i++) print line[i]}' \
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
# # FIX 1 (06.09.2026): changed pattern from "/<pre>/" (exact literal
# # match, requires the tag to have NO attributes) to "/<pre/" (matches
# # "<pre" as a prefix, regardless of any attributes). Root cause of the
# # scraper producing an empty iv.csv since ~03.08.2025: the source page
# # now renders the data block as <pre id="volContainer">...</pre>
# # instead of a bare <pre>...</pre> — the old exact-match pattern
# # silently matched zero lines, so every downstream step operated on
# # empty input.
# | sed -n "/<pre/,/<\/pre>/p" \
# # Use sed to remove any HTML tags from the text (also strips the new
# # nested <span class="vol-header">/<span class="vol-line"> wrappers
# # the page now uses around each line — no change needed here, the
# # generic any-attribute-tag pattern already handles them)
# | sed "s/<[^>]*>//g" \
# # Use sed to delete any lines that start with an asterisk
# | sed "/^\*/d" \
# # Use awk to delete the lines from the beginning through the LAST line
# # that starts with "Symbol" (not just the first).
# # FIX 2 (06.09.2026): the original "sed 1,/^Symbol/d" deletes only up
# # through the FIRST matching line — but the page now shows the header
# # text TWICE (once as a decorative teaser at the very top, once for
# # real right before the data), and since the teaser line IS line 1,
# # the sed range ends immediately, leaving the entire explanatory block
# # (units/column descriptions) in the output. Confirmed live: 4 of
# # those explanation lines happen to also have exactly 8 whitespace-
# # separated tokens by coincidence, so they weren't caught by the
# # later "NF==8" filter either and leaked into iv.csv as garbage rows
# # (e.g. "hv20:,20-day,HISTORICAL,(actual),volatility,of,the,underlying").
# # This awk replacement finds the LAST line matching /^Symbol/ (works
# # correctly whether the header appears once or twice) and keeps only
# # what comes after it — eliminates the whole explanatory block
# # regardless of its exact wording or line count, more robust than
# # pattern-matching around individual leaked lines.
# | awk '/^Symbol/{last=NR} {line[NR]=$0} END{for(i=last+1;i<=NR;i++) print line[i]}' \
# # Use sed to replace any sequence of spaces that is not preceded by a slash
# | sed "s/\\([^/ *]\\)  */\\1,/g" \
# # Use sed to delete any lines that contain OPTION
# | sed "/OPTION/d" \
# # Use sed to replace any occurrence of %ile followed by zero or more commas with %ile followed by one comma
# | sed "s/%ile,*/%ile,/g" \
# # Use awk to filter out any lines that do not have exactly eight fields separated by commas
# | awk -F, "NF==8" >> data.csv
