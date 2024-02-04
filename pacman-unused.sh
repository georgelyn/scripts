#!/bin/sh

# Stop script on NZEC
set -e
# Stop script if unbound variable found (use ${var:-} if intentional)
set -u

function main() {
	printf '%s\n' "Manages packages installed as dependencies and no longer required by other packages"
	print_help
}

function print_help() {
	printf '%s\n'
	printf '%s\n' "Posible actions:"
	printf '%s\n' "[a]: Show all"
	printf '%s\n' "[i]: Info about the package"
	printf '%s\n' "[r]: Remove package with other unused dependencies"
	printf '%s\n' "[e]: Change the installation reason to explicitly installed"
	printf '%s\n' "[h]: Show help"
	printf '%s\n' "[q]: Exit"
	printf '%s\n' "(default) Next (Ignore current package)"
	printf '%s\n'
}

function show_options() {
	printf "Action: " 
	read -r input
	if [ "$input" == "a" ]; then
		print_all
		printf '%s\n %s\n'
		show_options #"$1"
	elif [ "$input" == "i" ]; then
		print_pkg_info #"$1"
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
	elif [ "$input" == "q" ]; then
		exit 0
	fi
}

function print_pkg_info() {
	printf '%s\n'
	printf '%s\n' "$(pacman -Qi $pkg)"
	printf '%s\n'
}

function remove_pkg() {
	{ set -x; } &> /dev/null #echo on
	echo "$(sudo pacman -Runs $pkg)"
	{ set +x; } &> /dev/null #echo off
}

function set_as_explicit() {
	echo "$(sudo pacman -D --asexplicit $pkg)"
}

function print_all() {
	printf '%s\n' 
	printf "$(pacman -Qdtq)"
}

function print_current_pkg() {
	printf '%s\n' "Package: ${pkg}"
}

main

printf '%s\n' "Total packages: $(pacman -Qdtq | wc -l)"
printf '%s\n'

for pkg in $(pacman -Qdtq)
do
	print_current_pkg
	show_options
	printf '%s\n'
done
