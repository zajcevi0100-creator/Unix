#!/bin/sh
# build.sh - POSIX shell build script

set -u

[ $# -eq 1 ] || {
	echo "Ispolzovanie $0 ishodniy fail" >&2
	exit 1
}
src=$1

[ -f "$src" ] && [ -r "$src" ] || {
	echo "File ne naiden: $src" >&2
	exit 2
}

outname=$(sed -n 's/.*Output: *\([^ ]*\).*/\1/p' "$src" | head -n 1)

[ -n "$outname" ] || {
	echo "Не найдене комментарий Output: в $src" >&2
	exit 3
}

outname=$(basename "$outname")
src_dir=$(dirname "$src")
tmpdir=

cleanup_exit() {
	rc=$?
	trap - 0 1 2 3 13 15 
	[ -n "$tmpdir" ] && [ -d "$tmpdir" ] && rm -rf -- "$tmpdir"
	exit "$rc"
}

cleanup_signal(){
	sig=$1
	trap - 0 1 2 3 13 15
	[ -n "$tmpdir" ] && [ -d "$tmpdir" ] && rm -rf -- "$tmpdir"
	exit $((128 + sig))
}

trap 'cleanup_exit' 0  
trap 'cleanup_signal 1' 1
trap 'cleanup_signal 2' 2
trap 'cleanup_signal 3' 3
trap 'cleanup_signal 13' 13
trap 'cleanup_signal 15' 15

tmpdir=$(mktemp -d  "${TMPDIR:-/tmp}/build.XXXXXX") || {
	echo "mktemp failed" >&2
	exit 4
}

case "$src" in 
	*.c)
		cc -o "$tmpdir/$outname"  "$src" || {
			echo "Oshibka kompilacii C" >&2
			exit 5
		}
		;;
	*.cc|*.cpp|*.cxx|*.C)
		c++ -o "$tmpdir/$outname" "$src" || {
			echo  "Pshibka komp C++" >&2
			exit 5
		}
		;;
		*.tex)
		pdflatex -interaction=nonstopmode -halt-on-error \
			-output-directory="$tmpdir" "$src" > "$tmpdir/tex.log" 2>&1 || {
				echo "Oshibka komp tex" >&2
				exit 5
		}
		;;
	*)
		echo "Neppoderzh tip: $src" >&2
		exit 5
		;;
esac

