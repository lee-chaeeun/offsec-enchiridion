#!/usr/bin/env bash

# chmod_calc.sh
# Lookup Linux permissions from either octal or symbolic form
#
# Examples:
#   ./chmod_calc.sh 755
#   ./chmod_calc.sh 4755
#   ./chmod_calc.sh rwxr-xr-x
#   ./chmod_calc.sh -rwsr-xr-x
#   ./chmod_calc.sh drwxrwxrwt

set -u

usage() {
    cat <<EOF
Usage:
  $0 <permission>

Examples:
  $0 755
  $0 4755
  $0 rwxr-xr-x
  $0 -rwsr-xr-x
  $0 drwxrwxrwt

Input formats:
  - 3-digit octal: 755
  - 4-digit octal: 4755
  - 9-char symbolic: rwxr-xr-x
  - 10-char symbolic: -rwsr-xr-x or drwxrwxrwt
EOF
    exit 1
}

digit_to_symbolic() {
    case "$1" in
        0) echo "---" ;;
        1) echo "--x" ;;
        2) echo "-w-" ;;
        3) echo "-wx" ;;
        4) echo "r--" ;;
        5) echo "r-x" ;;
        6) echo "rw-" ;;
        7) echo "rwx" ;;
        *) return 1 ;;
    esac
}

special_bits_meaning() {
    local special="$1"
    local out=()

    (( special & 4 )) && out+=("SUID")
    (( special & 2 )) && out+=("SGID")
    (( special & 1 )) && out+=("Sticky")

    if [[ ${#out[@]} -eq 0 ]]; then
        echo "None"
    else
        printf '%s\n' "${out[*]}"
    fi
}

describe_triplet() {
    local label="$1"
    local triplet="$2"
    local meanings=()

    [[ "${triplet:0:1}" == "r" ]] && meanings+=("read")
    [[ "${triplet:1:1}" == "w" ]] && meanings+=("write")

    case "${triplet:2:1}" in
        x) meanings+=("execute") ;;
        s) meanings+=("execute + special bit") ;;
        S) meanings+=("special bit only (no execute)") ;;
        t) meanings+=("execute + sticky bit") ;;
        T) meanings+=("sticky bit only (no execute)") ;;
    esac

    if [[ ${#meanings[@]} -eq 0 ]]; then
        meanings=("no permissions")
    fi

    printf '%-7s %s -> %s\n' "$label" "$triplet" "${meanings[*]}"
}

octal_to_symbolic() {
    local oct="$1"
    local special="0"
    local u g o

    if [[ ${#oct} -eq 4 ]]; then
        special="${oct:0:1}"
        oct="${oct:1:3}"
    fi

    u="${oct:0:1}"
    g="${oct:1:1}"
    o="${oct:2:1}"

    local usym gsym osym
    usym="$(digit_to_symbolic "$u")" || return 1
    gsym="$(digit_to_symbolic "$g")" || return 1
    osym="$(digit_to_symbolic "$o")" || return 1

    if (( special & 4 )); then
        if [[ "${usym:2:1}" == "x" ]]; then
            usym="${usym:0:2}s"
        else
            usym="${usym:0:2}S"
        fi
    fi

    if (( special & 2 )); then
        if [[ "${gsym:2:1}" == "x" ]]; then
            gsym="${gsym:0:2}s"
        else
            gsym="${gsym:0:2}S"
        fi
    fi

    if (( special & 1 )); then
        if [[ "${osym:2:1}" == "x" ]]; then
            osym="${osym:0:2}t"
        else
            osym="${osym:0:2}T"
        fi
    fi

    local full="${usym}${gsym}${osym}"

    echo "Input:        $1"
    echo "Type:         Octal"
    echo "Symbolic:     $full"
    echo "Special bits: $(special_bits_meaning "$special")"
    echo
    describe_triplet "Owner" "$usym"
    describe_triplet "Group" "$gsym"
    describe_triplet "Other" "$osym"
}

symbolic_to_octal() {
    local sym="$1"
    local ftype=""
    local perms="$sym"

    if [[ ${#sym} -eq 10 ]]; then
        ftype="${sym:0:1}"
        perms="${sym:1:9}"
    fi

    [[ ${#perms} -eq 9 ]] || {
        echo "[!] Invalid symbolic permission string: $sym"
        exit 1
    }

    local u="${perms:0:3}"
    local g="${perms:3:3}"
    local o="${perms:6:3}"

    local special=0

    triplet_to_digit() {
        local t="$1"
        local val=0

        [[ "${t:0:1}" == "r" ]] && ((val+=4))
        [[ "${t:1:1}" == "w" ]] && ((val+=2))

        case "${t:2:1}" in
            x) ((val+=1)) ;;
            s) ((val+=1)) ;;
            S) ;;
            t) ((val+=1)) ;;
            T) ;;
        esac

        echo "$val"
    }

    [[ "${u:2:1}" =~ [sS] ]] && ((special+=4))
    [[ "${g:2:1}" =~ [sS] ]] && ((special+=2))
    [[ "${o:2:1}" =~ [tT] ]] && ((special+=1))

    local ud gd od
    ud="$(triplet_to_digit "$u")"
    gd="$(triplet_to_digit "$g")"
    od="$(triplet_to_digit "$o")"

    local oct="${ud}${gd}${od}"
    local full_oct="$oct"
    [[ "$special" -ne 0 ]] && full_oct="${special}${oct}"

    echo "Input:        $1"
    echo "Type:         Symbolic"
    [[ -n "$ftype" ]] && echo "File type:    $ftype"
    echo "Octal:        $full_oct"
    echo "Special bits: $(special_bits_meaning "$special")"
    echo
    describe_triplet "Owner" "$u"
    describe_triplet "Group" "$g"
    describe_triplet "Other" "$o"
}

main() {
    [[ $# -eq 1 ]] || usage

    local input="$1"

    if [[ "$input" =~ ^[0-7]{3}$ || "$input" =~ ^[0-7]{4}$ ]]; then
        octal_to_symbolic "$input"
    elif [[ "$input" =~ ^[-dlcbps][-rwxstST]{9}$ || "$input" =~ ^[rwxstST-]{9}$ ]]; then
        symbolic_to_octal "$input"
    else
        echo "[!] Unsupported format: $input"
        usage
    fi
}

main "$@"
