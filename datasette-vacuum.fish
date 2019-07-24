#!/usr/bin/fish

function help_usage
    echo 'Downloads paginated data as provided by datasette'
    echo ''
    echo 'Usage: datasette-vacuum https://example.com/datasette_url.csv out_file_name'
    exit
end

function vacuum --argument datasette_url out_file
    set counter 0
    set id -1
    while true
	set -l url (echo $datasette_url'?_stream=on&_size=max&id__gt='$id | sed 's/ //g')
	set -l file_name {$out_file}_(printf '%07d' $counter).csv 
	# there's a note at the end of a CSV if it exceeds the maximum size
	echo 'requesting '$url', saving to '/tmp/$file_name
        curl $url | sed 's/CSV contains more than.*$//' > /tmp/$file_name
        if test (xsv count /tmp/$file_name) -gt 0
            # the csv still contains some data, let's get the last id and continue
            set id (xsv select 'id' /tmp/$file_name | tail -n1)
        else
            # only the header is shown, we're done
            break
        end
        set counter (math $counter + 1)
    end
    set -l tmp_files /tmp/{$out_file}_*.csv
    xsv cat rows $tmp_files > {$out_file}.csv
    rm $tmp_files
end

if test (count $argv) -lt 2 -o "$argv[1]" = "--help"
    help_usage
end

vacuum $argv[1] $argv[2]
