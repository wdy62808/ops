#!/usr/bin/env bash
# https://github.com/dylanaraps/pure-bash-bible#strip-all-instances-of-pattern-from-string
trim_string() {
    # Usage: trim_string "   example   string    "
    # 删除字符串前后空格
    : "${1#"${1%%[![:space:]]*}"}"
    : "${_%"${_##*[![:space:]]}"}"
    printf '%s\n' "$_"
}
#trim_string "    Hello,  World    "

trim_all() {
    # Usage: trim_all "   example   string    "
    set -f
    set -- $*
    printf '%s\n' "$*"
    set +f
}
#trim_all "    Hello,    World    "

regex() {
    # Usage: regex "string" "regex"
    #匹配符合正则表示的 
    [[ $1 =~ $2 ]] && printf '%s\n' "${BASH_REMATCH[1]}"
}
#regex '    hello' '^\s*(.*)'

is_hex_color() {
    if [[ $1 =~ ^(#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3}))$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
    else
        printf '%s\n' "error: $1 is an invalid color."
        return 1
    fi
}

#read -r color
#is_hex_color "$color" || color="#FFFFFF"

split() {
   # Usage: split "string" "delimiter"
   IFS=$'\n' read -d "" -ra arr <<< "${1//$2/$'\n'}"
   printf '%s\n' "${arr[@]}"
}

#split "apples,oranges,pears,grapes" ","
#split "1, 2, 3, 4, 5" ", "

lower() {
    # Usage: lower "string"
    printf '%s\n' "${1,,}"
}
#lower "HELLO"

upper() {
    # Usage: upper "string"
    printf '%s\n' "${1^^}"
}
#upper "hello"

reverse_case() {
    # Usage: reverse_case "string"
    # 大写转小写 小写转大写
    printf '%s\n' "${1~~}"
}
#reverse_case "HeLlO"

trim_quotes() {
    # Usage: trim_quotes "string"
    : "${1//\'}"
    printf '%s\n' "${_//\"}"
}
#var="'Hello', \"World\""
#trim_quotes "$var"


strip_all() {
    # Usage: strip_all "string" "pattern"
    # 删除$2字符串包含的所有字符
    printf '%s\n' "${1//$2}"
}
#strip_all "The Quick Brown Fox" "[aeiou]"

strip() {
    # Usage: strip "string" "pattern"
    # Strip first occurrence of pattern from string
    printf '%s\n' "${1/$2}"
}
# strip "The Quick Brown Fox" "[aeiou]"
# res: Th Quick Brown Fox

var=xxxaasub_string
if [[ $var == *sub_string* ]]; then
    printf '%s\n' "sub_string is in var."
fi

# Inverse (substring not in string).
if [[ $var != *sub_string* ]]; then
    printf '%s\n' "sub_string is not in var."
fi

# This works for arrays too!
if [[ ${arr[*]} == *sub_string* ]]; then
    printf '%s\n' "sub_string is in array."
fi

reverse_array() {
    # Usage: reverse_array "array"
    shopt -s extdebug
    f()(printf '%s\n' "${BASH_ARGV[@]}"); f "$@"
    shopt -u extdebug
}

random_array_element() {
    # Usage: random_array_element "array"
    local arr=("$@")
    printf '%s\n' "${arr[RANDOM % $#]}"
}

random_array_element 1 2 3 4 5 6 7
sename() {
    # Usage: basename "path" ["suffix"]
    local tmp

    tmp=${1%"${1##*[!/]}"}
    tmp=${tmp##*/}
    tmp=${tmp%"${2/"$tmp"}"}

    printf '%s\n' "${tmp:-/}"
}
basename ~/Pictures/Wallpapers/1.jpg


