MSG=$1
CONFIRMTEXT=$2
CONFIRMCOLOR=$3

RED='\033[0;31m'
GREEN='\e[0;32m'
NC='\033[0m' #no color
echo -e "${!CONFIRMCOLOR}************************************************************************"
echo -e "${!CONFIRMCOLOR}${MSG}"
echo -e "${!CONFIRMCOLOR}************************************************************************"
printf "type ${CONFIRMTEXT} to confirm:${NC} "
read confirmDelete

if [ "$confirmDelete" != "${CONFIRMTEXT}" ]; then
	echo Aborting...
	exit 2
fi

