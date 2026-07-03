#!/bin/bash
#Author: Victor Bishop (Heretic312)
#Date Created: 3/13/25
#How It Works:
	#1.	Input Prompts: The script prompts the user for each section of the report.
	#2.	Markdown Formatting: It organizes the inputs into a structured Markdown file.
	#3.	Screenshots Handling: If screenshot paths are provided, it includes them in the Markdown file and ensures they are copied to the current directory.
	#4.	Export: The final report is saved as `bug_bounty_report.md`.
#Usage:
	#1.	Save this script as `generate_bug_bounty_report.sh`.
	#2.	Make it executable: `chmod +x generate_bug_bounty_report.sh`.
	#3.	Run the script: `./generate_bug_bounty_report.sh`.
	#4.	Follow the prompts to fill in details for your bug bounty report.
#This script ensures all required sections are included and formatted properly for easy sharing or submission.

# Function to prompt user for input
function prompt_input() {
    local prompt_text=$1
    local input_var
    echo -n "$prompt_text: "
    read -r input_var
    echo "$input_var"
}

# Function to generate the Markdown report
function generate_report() {
    local filename=$1

    # Collecting inputs for each section
    issue_description=$(prompt_input "Enter Issue Description")
    issue_identified=$(prompt_input "Enter Issue Identified Date")
    affected_url=$(prompt_input "Enter Affected URL/Area")
    risk_breakdown=$(prompt_input "Enter Risk Breakdown")
    steps_to_reproduce=$(prompt_input "Enter Steps to Reproduce")
    affected_demographic=$(prompt_input "Enter Affected Demographic/User Base")
    recommended_fix=$(prompt_input "Enter Recommended Fix or Remediation Steps")
    references=$(prompt_input "Enter References (comma-separated URLs)")
    screenshots=$(prompt_input "Enter Screenshot File Paths (comma-separated)")

    # Writing to the Markdown file
    echo "---" > "$filename"
    echo "title: Bug Bounty Report" >> "$filename"
    echo "date: $(date -Is)" >> "$filename"
    echo "---" >> "$filename"
    
    echo "" >> "$filename"
    echo "# Bug Bounty Report" >> "$filename"
    
    echo "" >> "$filename"
    echo "## Issue Description" >> "$filename"
    echo "$issue_description" >> "$filename"
    
    echo "" >> "$filename"
    echo "## Issue Identified" >> "$filename"
    echo "$issue_identified" >> "$filename"
    
    echo "" >> "$filename"
    echo "## Affected URL/Area" >> "$filename"
    echo "$affected_url" >> "$filename"
    
    echo "" >> "$filename"
    echo "## Risk Breakdown" >> "$filename"
    echo "$risk_breakdown" >> "$filename"

    echo "" >> "$filename"
    echo "## Steps to Reproduce" >> "$filename"
    echo "$steps_to_reproduce" >> "$filename"

    echo "" >> "$filename"
    echo "## Affected Demographic/User Base" >> "$filename"
    echo "$affected_demographic" >> "$filename"

    echo "" >> "$filename"
    echo "## Recommended Fix or Remediation Steps" >> "$filename"
    echo "$recommended_fix" >> "$filename"

    echo "" >> "$filename"
    echo "## References" >> "$filename"
    
    IFS=',' read -ra ref_array <<<"$references"
    for ref in "${ref_array[@]}"; do
        echo "- [$ref]($ref)" >> "$filename"
    done

    if [ -n "$screenshots" ]; then
        echo "" >> "$filename"
        echo "## Screenshots" >> "$filename"

        IFS=',' read -ra screenshot_array <<<"$screenshots"
        for screenshot in "${screenshot_array[@]}"; do
            if [ -f "$screenshot" ]; then
                # Assuming screenshots are in the same directory or accessible path
                screenshot_filename=$(basename -- "$screenshot")
                cp "$screenshot" .
                echo "![$screenshot_filename]($screenshot_filename)" >> "$filename"
            else
                echo "- Screenshot not found: $screenshot" >>"$filename"
            fi
        done
    fi

}

# Main script execution
output_file="bug_bounty_report.md"

echo "Generating Bug Bounty Report..."
generate_report $output_file

echo "Bug Bounty Report has been saved to $output_file."
