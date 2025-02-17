#!/bin/bash

# =======================================
# Section to obtain environment variables
# =======================================
# Getting environment variables from the .env file.
echo "Getting environment variables from the .env file."

# Load environment variables from .env file
if [ -f .env ]; then
    # Add a line break if there is none at the end of the file
    if [ $(tail -c1 .env | wc -l) -eq 0 ]; then
        echo "" >> .env
    fi

    while IFS='=' read -r name value; do
        # Trim whitespace from both ends of the line
        name=$(echo "$name" | xargs)
        value=$(echo "$value" | xargs)

        # Ensure the line isn't a comment or empty
        if [[ ! "$name" =~ ^# && -n "$value" ]]; then
            export "$name"="$value"
        fi
    done < .env
else
    echo "ERROR: .env file not found!"
    exit 1
fi

# Verify the database connection data in the environment variables of the ".env" file.
count=0
if [ -z "$DB_SERVER_NAME" ]; then
    count=$((count + 1))
fi
if [ -z "$DB_DATABASE_NAME" ]; then
    count=$((count + 1))
fi
if [ -z "$DB_USERNAME" ]; then
    count=$((count + 1))
fi
if [ -z "$DB_PASSWORD" ]; then
    count=$((count + 1))
fi
if [ $count -gt 0 ]; then
    echo "ERROR: Some environment variables were not found in the .env file."
    exit 1
fi
clear


# ===========================
# Section to choose an option
# ===========================
menuTitle="Select the option:"
menuOptions=(
    "RUN DO." 
    "RUN UNDO."
)
maxValue=$((${#menuOptions[@]} - 1))
selection=0
enterPressed=false

while [ "$enterPressed" == false ]; do
    # Print the menu title
    echo "$menuTitle"
    
    # Print each option with highlight for the selected one
    for i in $(seq 0 $maxValue); do
        if [ "$i" -eq "$selection" ]; then
            # Highlight the selected option with background color
            echo -e "\033[48;5;38m[ ${menuOptions[$i]} ]\033[0m"
        else
            echo "  ${menuOptions[$i]}  "
        fi
    done
    echo ""
    echo "Type Ctrl + C to exit."

    # Capture the user input (whole keypress sequence)
    read -rsn3 keyInput
    case $keyInput in
        "")  # Enter key (this is an empty string for enter)
            enterPressed=true
            ;;
        $'\x1B[A')  # Up arrow key
            echo "Up arrow key pressed"
            if [ "$selection" -eq 0 ]; then
                selection=$maxValue
            else
                selection=$((selection - 1))
            fi
            ;;
        $'\x1B[B')  # Down arrow key
            echo "Down arrow key pressed"
            if [ "$selection" -eq "$maxValue" ]; then
                selection=0
            else
                selection=$((selection + 1))
            fi
            ;;
        *)
            # In case of other keys, just redraw the screen
            echo "Other key pressed"
            ;;
    esac

    # Clear the screen and redraw the menu
    clear
done

# Confirming the selected option.
echo ""
echo "Your selected answer was:"
echo "> ${menuOptions[$selection]}"

read -p "Are you sure you want to execute this operation? (YES/NO): " confirm
if [ "$confirm" != "YES" ]; then
    echo ""
    echo "Your response was: $confirm"
    echo "The operation was aborted."
    exit 0
fi
clear


# ==========================
# Section to run the scripts
# ==========================
run_sqlcmd() {
    local path=$1
    # Execute sqlcmd and capture the output and errors.
    sqlcmd -S "$DB_SERVER_NAME" -U "$DB_USERNAME" -P "$DB_PASSWORD" -d "$DB_DATABASE_NAME" -i "$path" -b -f 65001 >> "$LOG_FILE" 2>&1
}

# Logs directory
LOG_DIR="logs"

# Create the logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log file inside the logs directory
if [ "$selection" -eq 0 ]; then
    LOG_FILE="$LOG_DIR/RUN_DO.log"
elif [ "$selection" -eq 1 ]; then
    LOG_FILE="$LOG_DIR/RUN_UNDO.log"
fi

# Clear the log file if it already exists, to start from scratch
> "$LOG_FILE"

# Function to redirect both stdout and stderr to a log file
log_output() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Start logging the execution
log_output "Starting execution at $(date)"

if [ "$selection" -eq 0 ]; then
    echo "Running ddl."
    run_sqlcmd "src/DO/ddl/dbo.UserOnRoles.sql"
    echo "Running functions."
    run_sqlcmd "src/DO/functions/dbo.rn_users.sql"
fi

if [ "$selection" -eq 1 ]; then
    echo "Running functions."
    run_sqlcmd "src/UNDO/functions/dbo.rn_users.sql"
    echo "Running ddl."
    run_sqlcmd "src/UNDO/ddl/dbo.UserOnRoles.sql"
fi

log_output "Execution completed at $(date)"
echo "Execution completed. Log saved to $LOG_FILE"
echo ""
