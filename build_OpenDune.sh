#!/usr/bin/env zsh

# ANSI colour codes
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Colour

# This just gets the location of the folder where the script is run from. 
SCRIPT_DIR=${0:a:h}
cd "$SCRIPT_DIR"

# Detect CPU architecture
ARCH_NAME="$(uname -m)"

# Get username
USER_NAME="$(id -un)"

# Introduction
echo "\n${PURPLE}This script is for compiling a native macOS build of:${NC}"
echo "${GREEN}OpenDune - Dune II: The Building of a Dynasty\n${NC}"

echo "${PURPLE}Place all the .PAK files from your original Dune II game data into:${NC}"
echo "${GREEN}/$USER_NAME/Library/Application Support/OpenDUNE/data${NC}\n"

echo "${PURPLE}${GREEN}Homebrew${PURPLE} and the ${GREEN}Xcode command-line tools${PURPLE} are required to build${NC}"
echo "${PURPLE}If they are not present you will be prompted to install them${NC}\n"

# Functions for checking for Homebrew installation
homebrew_check() {
	echo "${PURPLE}Checking for Homebrew...${NC}"
	if ! command -v brew &> /dev/null; then
		echo -e "${PURPLE}Homebrew not found. Installing Homebrew...${NC}"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		if [[ "${ARCH_NAME}" == "arm64" ]]; then 
			(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.zprofile
			eval "$(/opt/homebrew/bin/brew shellenv)"
			else 
			(echo; echo 'eval "$(/usr/local/bin/brew shellenv)"') >> $HOME/.zprofile
			eval "$(/usr/local/bin/brew shellenv)"
		fi
		
		# Check for errors
		if [ $? -ne 0 ]; then
			echo "${RED}There was an issue installing Homebrew${NC}"
			echo "${PURPLE}Quitting script...${NC}"	
			exit 1
		fi
	else
		echo -e "${PURPLE}Homebrew found. Updating Homebrew...${NC}"
		brew update
	fi
}

# Function for checking for an individual dependency
single_dependency_check() {
	if [ -d "$(brew --prefix)/opt/$1" ]; then
		echo -e "${GREEN}Found $1. Checking for updates...${NC}"
			brew upgrade $1
	else
		 echo -e "${PURPLE}Did not find $1. Installing...${NC}"
		brew install $1
	fi
}

# Install required dependencies
check_all_dependencies() {
	echo -e "${PURPLE}Checking for Homebrew dependencies...${NC}"
	# Required Homebrew packages
	deps=( cmake dylibbundler sdl2 sdl2_image )
	
	for dep in $deps[@]
	do 
		single_dependency_check $dep
	done
}

# Build the app bundle
build() {
	# removing any existing repo or app bundle
	rm -rf OpenDune
	rm -rf Dune\ II.app
	
	echo "${PURPLE}Cloning OpenDune repository...${NC}"
	git clone https://github.com/OpenDUNE/OpenDUNE
	cd OpenDune
	
	# Error check
	if [ $? -ne 0 ]; then
		echo -e "${RED}Error:${PURPLE} Could not clone OpenDune repository${NC}"
		exit 1
	fi
	
	echo "${PURPLE}Configuring build...${NC}"
	CC=clang ./configure
	
	# Error check
	if [ $? -ne 0 ]; then
		echo -e "${RED}Error:${PURPLE} Configuration failure${NC}"
		exit 1
	fi
	
	echo "${PURPLE}Building...${NC}"
	make && make bundle
	
	# Error check
	if [ $? -ne 0 ]; then
		echo -e "${RED}Error:${PURPLE} Build failure${NC}"
		exit 1
	fi
	
	mv ./bundle/OpenDUNE.app ../Dune\ II.app && cd ..
	
	echo "${PURPLE}Retrieving icon from macosicons.com...${NC}"
	curl -o Dune\ II.app/Contents/Resources/opendune.icns https://parsefiles.back4app.com/JPaQcFfEEQ1ePBxbf6wvzkPMEqKYHhPYv8boI1Rc/fbde57f7ea1ea965fbc8e16096542536_Dune_2.icns
	
	echo "${PURPLE}Bundling dependencies and codesigning...${NC}"
	dylibbundler -of -cd -b -x ./Dune\ II.app/Contents/MacOS/opendune -d ./Dune\ II.app/Contents/libs/
	
	echo "${PURPLE}Cleaning up...\n${NC}"
	rm -rf OpenDune
}

PS3='Would you like to continue? '
OPTIONS=(
	"Yes"
	"Quit")
select opt in $OPTIONS[@]
do
	case $opt in
		"Yes")
			homebrew_check
			check_all_dependencies
			build
			exit 0
			;;
		"Quit")
			echo -e "${RED}Quitting${NC}"
			exit 0
			;;
		*) 
			echo "\"$REPLY\" is not one of the options..."
			echo "Enter the number of the option and press enter to select"
			;;
	esac
done