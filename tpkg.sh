#!/bin/bash

# Package Manager Script - A script to fetch, compile, update packages, and show dependencies from a specified repository URL

# Set the repository URL where packages are hosted
url="yourwebsite.com/packages/"  # Replace with your website's URL
root="/home/richard/root"        # Absolute path of the root directory

# Change the current directory to the specified root directory
cd "$root"

# Check if the directory change was successful
if [ "$(pwd)" != "$root" ]; then
    echo -e "\033[0;31mCould not change directory to the root prefix.\033[0m"
    exit 1
fi

# Function: Package Installation
install_package() {
    local package_name="$1"
    
    # Check if package name is specified
    if [ -z "$package_name" ]; then
        echo -e "\033[0;31mPlease specify a package to install.\033[0m"
        exit 1
    elif [ -d "usr/tdb/$package_name" ]; then
        echo -e "\033[0;31m$package_name is already installed.\033[0m"
        exit 1
    fi

    # Create package URL
    package_url="$url$package_name/"
    
    # Check if the package exists in the repository
    package_check=$(curl -Is "$package_url" | head -n 1)
    
    if [[ $package_check == *"200"* ]]; then
        echo "$package_name package found. Proceeding with the installation."
    else
        echo -e "\033[0;31mAre you sure $package_name is spelled correctly?\033[0m"
        read -p "Do you want to proceed? [y/n]: " answer
        
        if [ "$answer" != "y" ]; then
            exit 1
        fi
    fi

    # Download the package from the URL
    echo "Downloading package..."
    busybox wget -cq "$package_url$package_name.tar"  # Get the package from the URL

    # Check if download was successful
    if [ "$?" = "0" ]; then
        echo "Download successful. Compiling package..."
        tar -xf "$package_name.tar"
        rm "$package_name.tar"
        echo "Installation successful."

        # Logging: Create a log file for installed packages
        if [ ! -d "/home/$(whoami)/.tpkg/" ]; then
            mkdir -p "/home/$(whoami)/.tpkg/"
        fi

        if [ ! -f "/home/$(whoami)/.tpkg/installed.txt" ]; then
            touch "/home/$(whoami)/.tpkg/installed.txt"
        fi

        if [ ! -f "/home/$(whoami)/.tpkg/removed.txt" ]; then
            touch "/home/$(whoami)/.tpkg/removed.txt"
        fi

        echo "$package_name installed on $(date)" >> "/home/$(whoami)/.tpkg/installed.txt"
    else
        echo -e "\033[0;31mInstallation failed.\033[0m"
        exit 1
    fi
}

# Function: Package Removal
remove_package() {
    local package_name="$1"
    
    # Check if package name is specified
    if [ -z "$package_name" ]; then
        echo -e "\033[0;31mPlease specify a package to remove.\033[0m"
        exit 1
    elif [ ! -d "usr/tdb/$package_name" ]; then
        echo -e "\033[0;31m$package_name is not installed.\033[0m"
        exit 1
    fi
    
    # Package removal process
    # ...

    echo "$package_name successfully removed."
}

# Function: Package Update
update_package() {
    local package_name="$1"
    
    # Check if package name is specified
    if [ -z "$package_name" ]; then
        echo -e "\033[0;31mPlease specify a package to update.\033[0m"
        exit 1
    elif [ ! -d "usr/tdb/$package_name" ]; then
        echo -e "\033[0;31m$package_name is not installed.\033[0m"
        exit 1
    fi
    
    # Fetch the latest version from the repository
    latest_version=$(curl -s "$url$package_name/latest_version.txt")
    current_version=$(cat "usr/tdb/$package_name/version.txt")

    if [ "$latest_version" != "$current_version" ]; then
        echo "Updating $package_name from version $current_version to $latest_version..."
        
        # Download the latest package version from the repository
        echo "Downloading latest package..."
        busybox wget -cq "$url$package_name/$latest_version/$package_name.tar"

        # Check if download was successful
        if [ "$?" = "0" ]; then
            echo "Download successful. Compiling package..."
            tar -xf "$package_name.tar"
            rm "$package_name.tar"
            echo "Update successful."

            # Update the version file
            echo "$latest_version" > "usr/tdb/$package_name/version.txt"
        else
            echo -e "\033[0;31mUpdate failed. Unable to download the latest version.\033[0m"
            exit 1
        fi
    else
        echo "$package_name is already up-to-date."
    fi
}

# Function: List All Packages
list_packages() {
    echo "Installed packages:"
    ls -1 usr/tdb/
}

# Function to check dependencies
check_dependencies() {
    # Check if 'curl', 'busybox', and 'tar' commands exist
    if ! command -v curl &> /dev/null || ! command -v busybox &> /dev/null || ! command -v tar &> /dev/null; then
        echo -e "\033[0;31mThis script requires 'curl', 'busybox', and 'tar' to function properly.\033[0m"
        echo "Please install these dependencies before running the script."
        exit 1
    fi
}

# Function: Package Dependency Check
check_package_dependencies() {
    local package_name="$1"
    
    # Check if package name is specified
    if [ -z "$package_name" ]; then
        echo -e "\033[0;31mPlease specify a package to check its dependencies.\033[0m"
        exit 1
    elif [ ! -d "usr/tdb/$package_name" ]; then
        echo -e "\033[0;31m$package_name is not installed.\033[0m"
        exit 1
    fi
    
    # List dependencies of the package if a 'dependencies.txt' file exists
    if [ -f "usr/tdb/$package_name/dependencies.txt" ]; then
        echo "Dependencies for $package_name:"
        cat "usr/tdb/$package_name/dependencies.txt"
    else
        echo "No dependencies found for $
