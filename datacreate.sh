#!/bin/bash

# Define input and output files
input_file="MUTATIONS.csv.gz"
output_file="tuberculosis_mutations.csv"

# Extract unique gene names from the second column of the CSV file
genes=$(zcat "$input_file" | cut -d ',' -f 2 | tail -n +2 | sort | uniq)

# Generate header
header="SampleID,$(echo "$genes" | tr '\n' ',' | sed 's/,$//')"

# Print header to output file
echo "$header" > "$output_file"
# Process the gzipped CSV file in chunks
zcat "$input_file" | awk -v genes="$genes" '
    BEGIN {
        FS=",";
        OFS=",";
        split(genes, arr, "\n");
        chunk_size=10000; # Adjust chunk size as needed
    }
    {
        sampleID = $1;
        gene = $2;
        mutations[sampleID,gene] = 1;
        samples[sampleID] = 1;

        # Process and output mutations if chunk size is reached
        if (NR % chunk_size == 0) {
            for (sampleID in samples) {
                printf "%s", sampleID;
                for (i = 1; i <= length(arr); i++) {
                    printf "%s", (arr[i] in mutations[sampleID]) ? ",1" : ",0";
                }
                printf "\n";
            }
            delete samples;
            delete mutations;
        }
    }
    END {
        # Process and output mutations for the remaining lines
        for (sampleID in samples) {
            printf "%s", sampleID;
            for (i = 1; i <= length(arr); i++) {
                printf "%s", (arr[i] in mutations[sampleID]) ? ",1" : ",0";
            }
            printf "\n";
        }
    }
' >> "$output_file"