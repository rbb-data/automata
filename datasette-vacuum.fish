#!/usr/bin/fish

function help_usage
    echo 'Helper to download paginated datasette-hosted data.'
    echo ''
    echo 'Usage: datasette-vacuum https://example.com/datasette_url out_file_name'
    exit
end

function vacuum --argument datasette_url out_file
    # clean input arguments
    set out_file (echo $out_file | sed 's/.csv$//')
    set datasette_url (echo $datasette_url | sed 's/\?.*$//; s/.json$//; s/.csv//')

    # set up loop vars
    set counter 0
    set id -1
    set idcol_name 'id' # we assume the id is in the first column
    while true
	set -l url (echo $datasette_url'.csv?_stream=on&_size=max&'{$idcol_name}'__gt='$id | sed 's/ //g')
	set -l file_name {$out_file}_(printf '%07d' $counter).csv 
	# there's a note at the end of a CSV if it exceeds the maximum size
	echo 'requesting '$url', saving to '/tmp/$file_name
        curl $url | sed 's/CSV contains more than.*$//' > /tmp/$file_name
        if test (xsv count /tmp/$file_name) -gt 0
            # the csv still contains some data, let's get the last id and continue
	    set idcol_name (xsv select 1 /tmp/$file_name | head -n1)
            set id (xsv select 1 /tmp/$file_name | tail -n1)
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
