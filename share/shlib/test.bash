#function declare() {
#    command declare "$@"
#}

function include() {
    local f="$1"
    declare -Agx _A_HASH_DECLARED_IN_A_FUNCTION
    _A_HASH_DECLARED_IN_A_FUNCTION=( [wk]=~/wk  [pristine]=~/wk-pristine )
    _A_VAR_DECLARED_IN_A_FUNCTION=42
    declare -ga _A_ARRAY_DECLARED_IN_FUNCTION
    _A_ARRAY_DECLARED_IN_FUNCTION=("ta" "chi" "tsu")
    source "$f"
    local
#echo "${_A_ARRAY_DECLARED_IN_FILE_SOURCED_BY_FUNCTION[*]}"
#sleep 3
#echo "${_A_ARRAY_DECLARED_IN_FILE_SOURCED_BY_FUNCTION[*]}"
#sleep 3
}

function create_hash() {
    local name="$1"
    declare -gAx "$name"
}

declare -ag _A_ARRAY_DECLARED_IN_SOURCED_FILE=("ta" "chi" "tsu")
