#!/usr/bin/env bash
set -e

function printCurrency() {
    LC_NUMERIC=en_US.utf8 printf "%'d Ft" "$1" | tr ',' ' '
    # LC_NUMERIC=en_US printf "%'d Ft" "$1" | tr ',' ' '
}

[[ $# -ne 2 || ! -f $1 || ! -d $2 ]] && echo "Használat: #0 <config file> <output dir>" >&2 && exit 1
source "$1"
# Check myNumbers
[[ -z $myNumbers ]] && echo "A myNumbers definiálása kötelező!" >&2 && exit 1
[[ ${#myNumbers[@]} -ne $[(${#myNumbers[@]} / 5) * 5] ]] && echo "A myNumbers tömbben ötösével kell felsorolni a szelvényeket!" >&2 && exit 1
for i in ${!myNumbers[@]}; do
    [[ ${myNumbers[$i]} -le 0 || ${myNumbers[$i]} -gt 90 ]] && echo "A számoknak 1 és 90 között kell lenniük!" >&2 && exit 1
done

# Check numberOfPlayers
[[ -z $numberOfPlayers ]] && numberOfPlayers=1
[[ $numberOfPlayers -le 0 ]] && echo "A numberOfPlayers-nek pozitív egész számnak kell lennie, ha definiálva van!" >&2 && exit 1

latest="$(wget -qO - https://bet.szerencsejatek.hu/cmsfiles/otos.csv | head -1 | tr -d '\r')"
# latest="$(date +%Y);$(date +%W);$(date +%Y.%m.%d.);0;0 Ft;34;1 592 600 Ft;2615;22 085 Ft;72302;1 745 Ft;14;28;30;52;84"
# latest=
[[ -z $latest || $(awk -F ';' '{print NF}' <<< "$latest") -ne 16 ]] && exit 0 # Probably a transient error

year="$(cut -d ';' -f 1 <<< "$latest")"
week="$(cut -d ';' -f 2 <<< "$latest")"
drawDate="$(cut -d ';' -f 3 <<< "$latest")"
declare -A winerCounts=(
    [5]="$(cut -d ';' -f 4 <<< "$latest")"
    [4]="$(cut -d ';' -f 6 <<< "$latest")"
    [3]="$(cut -d ';' -f 8 <<< "$latest")"
    [2]="$(cut -d ';' -f 10 <<< "$latest")"
)
declare -A winnings=(
    [5]="$(cut -d ';' -f 5 <<< "$latest" | tr -cd '[:digit:]')"
    [4]="$(cut -d ';' -f 7 <<< "$latest" | tr -cd '[:digit:]')"
    [3]="$(cut -d ';' -f 9 <<< "$latest" | tr -cd '[:digit:]')"
    [2]="$(cut -d ';' -f 11 <<< "$latest" | tr -cd '[:digit:]')"
)
declare numbers=(
    "$(cut -d ';' -f 12 <<< "$latest")"
    "$(cut -d ';' -f 13 <<< "$latest")"
    "$(cut -d ';' -f 14 <<< "$latest")"
    "$(cut -d ';' -f 15 <<< "$latest")"
    "$(cut -d ';' -f 16 <<< "$latest")"
)

{
    # Print draw stats
    cat << EOF



Utolsó húzás: $drawDate ($year/$week. hét)
Számok: ${numbers[0]}, ${numbers[1]}, ${numbers[2]}, ${numbers[3]}, ${numbers[4]}
Kiosztott nyeremények: 
EOF
    for i in {5..2}; do
        if [[ ${winerCounts[$i]} -ne 0 ]]; then
            echo "   $i találatosból ${winerCounts[$i]} db, a nyeremény $(printCurrency ${winnings[$i]})"
        fi
    done

    # Print myNumbers
    echo "Szelvények:"
    for ((i=0; i < ${#myNumbers[@]} / 5; i++)); do
        echo -n "   $[i + 1]:"
        for ((j=0; j < 5; j++)); do
            idx=$[i * 5 + j]
            printf " %2d" "${myNumbers[$idx]}"
        done
        echo
    done

    # Search for matches
    declare -A matchCounts=( )
    for ((i=0; i < ${#myNumbers[@]} / 5; i++)); do
        matchCount=0
        for ((j=0; j < 5; j++)); do
            idx=$[i * 5 + j]
            for ((k=0; k < ${#numbers[@]}; k++)); do
                if [[ ${myNumbers[$idx]} -eq ${numbers[$k]} ]]; then
                    matchCount=$[matchCount + 1]
                fi
            done
        done
        [[ $matchCount -ge 2 ]] && matchCounts[$i]=$matchCount
    done

    # Print result
    if [[ ${#matchCounts[@]} -gt 0 ]]; then
        totalWin=0

        echo "Találatok:"
        for i in ${!matchCounts[@]}; do
            win=${winnings[${matchCounts[$i]}]}
            echo "   $[i + 1]. szelvény: ${matchCounts[$i]} találat, $(printCurrency $win)"
            totalWin=$[totalWin + win]
        done

        echo -n "Összesen $(printCurrency $totalWin)"
        if [[ $numberOfPlayers -gt 1 ]]; then
            echo ", ami $numberOfPlayers részre osztva fejenként $(printCurrency $[totalWin / numberOfPlayers])"
        else
            echo
        fi
    else
        echo "Sajnos ma nincs nyeremény :("
    fi
} > "$2/out.new"

# Print output if differs from previous
if [[ -f $2/out.last ]]; then
    if ! cmp -s "$2/out.last" "$2/out.new"; then
        mv "$2/out.new" "$2/out.last"
        cat "$2/out.last"
        exit 1
    else
        rm "$2/out.new"
    fi
else
    mv "$2/out.new" "$2/out.last"
    cat "$2/out.last"
    exit 1
fi
