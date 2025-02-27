#!/bin/sh

# Stop script if unbound variable found (use ${var:-} if intentional)
set -u

exit_loop=false
current_pkg=""
option=0

function start_loop() {
	for pkg in $(pacman -Qdtq)
	do
		current_pkg=$pkg
		print_current_pkg
		show_options
		printf '%s\n'
		
		if $exit_loop; then
			break
		fi
	done
}

function main() {
	printf '%s\n' "Manages packages installed as dependencies and no longer required by other packages"
	print_help
	start_loop

	process_option $option
}

function print_help() {
	printf '%s\n'
	printf '%s\n' "Posible actions:"
	printf '%s\n' "[restart]: Restart the process"
	if [ $option != 1 ]; then
		printf '%s\n' "[a]: Show all"
	fi
	printf '%s\n' "[i]: Info about the package"
	printf '%s\n' "[r]: Remove package with other unused dependencies"
	printf '%s\n' "[e]: Change the installation reason to explicitly installed"
	printf '%s\n' "[s]: Specify a package by name"
	printf '%s\n' "[h]: Show help"
	printf '%s\n' "[q]: Exit"
	if [ $option != 1 ]; then
		printf '%s\n' "(default) Next (Ignore current package)"
	fi
	printf '%s\n'
}

function show_options() {
	forced_option=""
	input=""
	if [[ $# -gt 0 ]]; then
		forced_option="$1"
	fi
	
	if [ -z "$forced_option" ]; then
		printf "Action: " 
		read -r input
	else
		input=$forced_option
	fi

	if [ "$input" == "a" ] && [ $option != 1 ]; then
		print_all
		printf '%s\n %s\n'
		show_options
	elif [ "$input" == "i" ]; then
		print_pkg_info
		print_current_pkg
		show_options
	elif [ "$input" == "e" ]; then
		set_as_explicit
		show_options
	elif [ "$input" == "r" ]; then
		printf $(remove_pkg)
		printf '%s\n'
	elif [ "$input" == "h" ]; then
		print_help
		print_current_pkg
		show_options
	elif [ "$input" == "s" ]; then
		printf "Enter package: " 
		read -r selected_package
		check_package_existance "$selected_package"
		
		if [[ $? -eq 0 ]]; then
			clear
			printf '%s\n'
			echo -e "\e[1;31mError:\e[0m The package ["${selected_package}"] is invalid or not installed"
			show_options "h"
		else
			current_pkg=$selected_package
			exit_loop=true
			option=1
		fi

	elif [ "$input" == "restart" ]; then
		clear
		printf '%s\nRestarting...'
		printf '%s\n'
		printf '%s\n'
		main
	elif [ "$input" == "q" ] || [ "$input" == "exit" ]; then
		exit 0
	elif [ $option == 1 ]; then
		show_options
	fi
}

function print_pkg_info() {
	printf '%s\n'
	printf '%s\n' "$(pacman -Qi $current_pkg)"
	printf '%s\n'
}

function remove_pkg() {
	{ set -x; } &> /dev/null
	echo "$(sudo pacman -Runs $current_pkg)"
	printf '%s\n'
	{ set +x; } &> /dev/null
}

function set_as_explicit() {
	echo "$(sudo pacman -D --asexplicit $current_pkg)"
}

function print_all() {
	printf '%s\n' 
	printf "$(pacman -Qdtq)"
}

function print_current_pkg() {
	printf '%s\n' "Package: ${current_pkg}"
}

function check_package_existance() {
	if pacman -Qi "$1" > /dev/null 2>&1; then 
		return 1
	else
		return 0
	fi
}

function process_option() {
	if [ $1 == 1 ]; then
		print_current_pkg
		show_options
		start_loop
	else
		exit 0
	fi
}

main

printf '%s\n' "Total packages: $(pacman -Qdtq | wc -l)"
printf '%s\n'


