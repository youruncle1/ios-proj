#!/bin/sh
#!/bin/bash
export POSIXLY_CORRECT=yes

print_help(){
    echo HELP
    echo corona - COVID-19 data analyzer
    echo corona - [-h] [FILTERS] [COMMAND] [LOG [LOG2 [...]]]
    echo
    echo COMMANDS:
    echo    infected - counts number of infected
    echo    merge - unites multiple files into one "(original order will be maintained)"
    echo    gender - return amount of infected for both genders
    echo    age - returns data for various age groups
    echo    daily - returns data for specific days
    echo    monthly - returns data for specific months
    echo    yearly - returns data for specifc years
    echo    countries - returns data for various countries "(excluding Czech Republic)"

}

infected(){
    echo  "$FILTERED" | awk   -v count=0 '{count++} END {print count}'
    exit 0
}

gender(){
    if [ $FILTER_WIDTH == "NOTHING" ];then
        echo  "$FILTERED" | awk -F ',' -v count=0 '/,M,/ {count++} END {print "M: " count}'
        echo  "$FILTERED" | awk -F ',' -v count=0 '/,Z,/ {count++} END {print "Z: " count}'
    elif [ $FILTER_WIDTH == "CLASSIC" ]; then
        echo "$FILTERED" | sort -t, -k4,4 | awk -F ',' -v count=1 -v  width=100000 '/,M,/ {count++}\
        END {printf("M: ")}\
        END {for (i=0; i < count/width-1; i++)\
        printf("#") }\
        END {printf("\n")}'

        echo "$FILTERED" | sort -t, -k4,4 | awk -F ',' -v count=1 -v  width=100000 '/,Z,/ {count++}\
        END {printf("Z: ")}\
        END {for (i=0; i < count/width-1; i++)\
        printf("#") }\
        END {printf("\n")}'
    else
        echo "$FILTERED" | sort -t, -k4,4 | awk -F ',' -v count=0 -v  width="$FILTER_WIDTH" '/,M,/ {count++}\
        END {printf("M: ")}\
        END {for (i=0; i < count/width; i++)\
        printf("#") }\
        END {printf("\n")}'

        echo "$FILTERED" | sort -t, -k4,4 | awk -F ',' -v count=0 -v  width="$FILTER_WIDTH" '/,Z,/ {count++}\
        END {printf("Z: ")}\
        END {for (i=0; i < count/width; i++)\
        printf("#") }\
        END {printf("\n")}'

    fi

}



FILES=""
FILTER_GENDER=""
FILTER_DATE_A="0000-00-00"
FILTER_DATE_B="9999-00-00"
FILTER_WIDTH="NOTHING"
COMMAND="NOTHING"
RE="^[0-9]+$"

while [ "$#" -gt 0 ]; do
    case "$1" in

    infected | merge | gender | age | daily | monthly | yearly | countries | districts | regions)
        COMMAND="$1"
        shift
        ;;

    -h)
        print_help
        exit 0
        ;;

    -s)
        FILTER_WIDTH="CLASSIC"
        shift
        ;;

    -g)
        if [ "$2" == "Z" ]; then
            FILTER_GENDER="$2"
        fi
        if [ "$2" == "M" ]; then
            FILTER_GENDER="$2"
        fi
        shift
        shift
        ;;

    -a)
        FILTER_DATE_A="$2 $FILTER_DATE"
        shift
        shift
        ;;

    -b)
        FILTER_DATE_B="$2"
        shift
        shift
        ;;

    *)
        FILES="$1 $FILES"
        shift
        ;;

    esac
done

#echo "$COMMAND"
#---------------------------------------------------------FILTERING-----------------------------------------------------------
READ_FILES=$(cat $FILES)

#FILTERING DATE
FILTERED=$(echo "$READ_FILES" | awk -F ',' -v dateA="$FILTER_DATE_A" -v dateB="$FILTER_DATE_B" '{if($2 > dateA && $2< dateB) {print }}')

#FILTERING GENDER
if [ "$FILTER_GENDER" == "M" ]; then
    FILTERED=$(echo "$FILTERED"| awk -F "," '/,M,/ {print}')
fi
if [ "$FILTER_GENDER" == "Z" ]; then
    FILTERED=$(echo "$FILTERED"| awk -F "," '/,Z,/ {print}')
fi

#-----------------------------------------------------CHECKING COMMANDS-------------------------------------------------------
#no need to check commands if no were given
if [ $COMMAND == "NOTHING" ]; then
    echo "$FILTERED"
    exit 0
fi

#INFECTED
if [ $COMMAND == "infected" ]; then
    infected
    exit 0
fi

#GENDER
if [ $COMMAND == "gender" ]; then
    gender
    exit 0
fi

#DAILY
if [ $COMMAND == "daily" ]; then
    echo "$FILTERED" | sort -t, -k2,2 | awk -F ',' 'BEGIN{
    day = ""
    daySum = 1
    }{
    if (day== ""){
        day = $2
    }
    else if (day == $2)
    {
        daySum++
    }
    else
    {
        printf("%s :%d\n", day, daySum)
        daySum = 1
        day=$2
    }}
    END{printf("%s: %d\n", day, daySum)}'

fi

if [ $COMMAND == "yearly" ]; then
    echo "$FILTERED" | sort -t, -k2,2 | awk -F ',' 'BEGIN{
    year = ""
    yearSum = 1
    }{
    if (year== ""){
        year = substr($2 ,1, 4)
    }
    else if (year == substr($2 ,1, 4))
    {
        yearSum++
    }
    else
    {
        printf("%s :%d\n", year, yearSum)
        yearSum = 1
        year = substr($2 ,1 ,4)
    }}
    END{printf("%s :%d\n", year, yearSum)}'
fi



if [ $COMMAND == "monthly" ]; then
    echo "$FILTERED" | sort -t, -k2,2 | awk -F ',' 'BEGIN{
    month = ""
    monthSum = 1
    }{
    if (month== ""){
        month = substr($2 ,1, 7)
    }
    else if (month == substr($2 ,1, 7))
    {
        monthSum++
    }
    else
    {
        printf("%s :%d\n", month, monthSum)
        monthSum = 1
        month = substr($2 ,1 ,7)
    }}
    END{printf("%s :%d\n", month, monthSum)}'
fi

#echo "$FILTERED"

