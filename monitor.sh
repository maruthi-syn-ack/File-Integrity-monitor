#!/bin/bash

# Function to calculate SHA-512 hash of a file
calculate_file_hash() {
    file_path="$1"
    sha512sum "$file_path" | awk '{print $1}'
}

# Function to erase baseline.txt if it already exists
erase_baseline_if_already_exists() {
    if [ -e "./baseline.txt" ]; then
        # Delete it
        rm "./baseline.txt"
    fi
}

echo ""
echo "What would you like to do?"
echo ""
echo "    A) Collect new Baseline?"
echo "    B) Begin monitoring files with saved Baseline?"
echo ""
read -p "Please enter 'A' or 'B': " response
echo ""

response=$(echo "$response" | tr '[:lower:]' '[:upper:]') # Convert the response to uppercase

if [ "$response" = "A" ]; then
    # Delete baseline.txt if it already exists
    erase_baseline_if_already_exists

    # Calculate Hash from the target files and store in baseline.txt
    # Collect all files in the target folder
    files=$(find ./Files -type f)

    # For each file, calculate the hash, and write to baseline.txt
    for f in $files; do
        hash=$(calculate_file_hash "$f")
        echo "$f|$hash" >> "./baseline.txt"
    done

elif [ "$response" = "B" ]; then
    declare -A fileHashDictionary

    # Load file|hash from baseline.txt and store them in a dictionary
    while IFS='|' read -r file_path hash; do
        fileHashDictionary["$file_path"]=$hash
    done < "./baseline.txt"

    # Begin (continuously) monitoring files with saved Baseline
    while true; do
        sleep 1
        # Clear the screen
        echo -e "\033[2J"
        files=$(find ./Files -type f)

        # For each file, calculate the hash, and compare with baseline
        for f in $files; do
            hash=$(calculate_file_hash "$f")

            # Notify if a new file has been created
            if [ -z "${fileHashDictionary["$f"]}" ]; then
                # A new file has been created!
                echo "$(tput setaf 2)$f has been created ! $(tput sgr0)"
                 # You can customize the output with different colors using echo -e or tput commands.
            else
                # Notify if a file has been changed
                if [ "${fileHashDictionary["$f"]}" = "$hash" ]; then
                    # The file has not changed
                    :
                else
                    # The file has been compromised! Notify the user
                    echo "$(tput setaf 4)$f has changed!!! .$(tput sgr0)"
                     # You can customize the output with different colors using echo -e or tput commands.
                fi
            fi
        done

        # Check if any of the baseline files have been deleted
        for key in "${!fileHashDictionary[@]}"; do
            if [ ! -e "$key" ]; then
                # One of the baseline files must have been deleted, notify the user
                echo "$(tput setaf 1)$key has been deleted!$(tput sgr0)"
                
            fi
        done
    done

else
    echo "$(tput setaf 6)Invalid option selected. Please enter 'A' or 'B'.$(tput sgr0)"
fi
