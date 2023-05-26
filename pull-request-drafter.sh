TARGET_BRANCH=main
SOURCE_BRANCH=demo
default_format="%s - %h"
hide_words=("feat" "fix")

# Read template from template.md
template=$(cat template.md)

# Get git commits
printed=()

# For each %*% in template.md, replace it with the git log
while read -r line; do
    # sample line : "feat:" options="..." hide-prefix
    # "first thing" "second thing" "third thing" --> first thing
    keyword=$(echo "${line}" | cut -d'"' -f2)
    options=$(echo "${line}" | grep -o "options=\".*\"" | sed 's|options="||' | sed 's/"$//g')

    GIT_LOG_command="git log --graph --format=\"$default_format\" --abbrev-commit \"origin/${TARGET_BRANCH}...origin/${SOURCE_BRANCH}\" $options"
    # Execute git log command
    GIT_LOG=$(eval $GIT_LOG_command)

    if [[ $keyword == "all commits" ]]; then
        GIT_LOG_selected=$GIT_LOG

    elif [[ $keyword == "rest commits" ]]; then
        # Filter commits that are already selected
        GIT_LOG_selected=$(echo "$GIT_LOG" | grep -i -v -f <(echo -e ${printed[@]} | sed 's/  */ /g' | tr ' ' '\n'))
        GIT_LOG=$(eval "$GIT_LOG_command --format=\"%s^_^_%h^_^_\"" | grep -i "$keyword" | grep -o "\^_\^_.*\^_\^_" | tr '*' ' ' | tr '\n' ' ' | sed 's/  */ /g')

    else
        GIT_LOG_selected=$(echo "$GIT_LOG" | grep -i "$keyword")
        [[ -n $(echo "${line}" | grep -o "hide-prefix") ]] && GIT_LOG_selected=${GIT_LOG_selected//$keyword}
        # Remove * and \n, Add commit hash to printed array
        GIT_LOG=$(eval "$GIT_LOG_command --format=\"%s^_^_%h^_^_\"" | grep -i "$keyword" | grep -o "\^_\^_.*\^_\^_" | tr '*' ' ' | tr '\n' ' ' | sed 's/  */ /g')
        printed+=("${GIT_LOG//'^_^_'}")
    fi

    # Replace \n, *, multiple spaces
    GIT_LOG_selected=$(echo -e "${GIT_LOG_selected}" | tr '#' '^HaSz^' | sed 's/  */ /g' | sed ':a;N;$!ba; s/\n/^NowALiNiA^/g' | sed "s\^* \- \g" | sed 's|&|\\&|g')
    # Replace both %$line and %$line %
    template=$(echo -e "${template}" | sed "s|${line}|${GIT_LOG_selected}|g")

done < <(echo -e "${template}" | grep -o "<!--.*-->")

template=$(echo -e "${template}"  | sed '1h;2,$H;$!d;g; s|\^NowALiNiA\^\* |\\n- |g')
echo -e "${template}" > PR.md