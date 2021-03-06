#!/bin/bash
set -o nounset
set -o errexit

ENDPOINTS="hamm5;hamm6;dresden2"

USAGE_START_DATE=2015-01-01
USAGE_END_DATE=2015-04-04

PRICE_XS_MONTH="14.60" #monthly
PRICE_S_MONTH="29.20"
PRICE_M_MONTH="58.40"
PRICE_L_MONTH="102.20"

INSTANCE_FILTER=leads- # get only leads machiens
INSTANCE_STATE=Running

echo $(echo $ENDPOINTS | tr ';' ' ')

echo '|          FROM '$USAGE_START_DATE' TO '$USAGE_END_DATE'             |'

flavors=""
for ep in $(echo $ENDPOINTS | tr ";" "\n"); do
	AUTH_URL="https://identity-${ep}.cloudandheat.com:5000/v2.0"

    echo '|                  '$ep'                             |'
    echo "| Servers | RAM MB-Hours | CPU Hours | Disk GB-Hours |"
     nova --os-auth-url=${AUTH_URL} usage --start $USAGE_START_DATE --end $USAGE_END_DATE |\
	    grep '|' | egrep [0-9]+ 
	
	f=$(nova --os-auth-url=$AUTH_URL list | grep -v '\-\-\-' | grep $INSTANCE_FILTER | grep $INSTANCE_STATE | cut -d'|' -f2 | tr -d ' '  | xargs -I {} nova --os-auth-url=$AUTH_URL show {} | grep flavor | cut -d'|' -f3)
	flavors="${flavors} ${f}"
done 

#echo $flavors

set +o errexit
num_xs=$(echo "$flavors" | grep -c 'cloudcompute.xs')
num_s=$(echo "$flavors"  | grep -c 'cloudcompute.s')
num_m=$(echo "$flavors"  | grep -c 'cloudcompute.m')
num_l=$(echo "$flavors"  | grep -c 'cloudcompute.l')
set -o errexit

cost_xs=$(echo "${num_xs}*${PRICE_XS_MONTH}" | bc)
cost_s=$(echo "${num_s}*${PRICE_S_MONTH}" | bc)
cost_m=$(echo "${num_m}*${PRICE_M_MONTH}" | bc)
cost_l=$(echo "${num_l}*${PRICE_L_MONTH}" | bc)

echo "xs: ${num_xs} * ${PRICE_XS_MONTH} = ${cost_xs} (E/month)"
echo " s: ${num_s}  * ${PRICE_S_MONTH} = ${cost_s} (E/month)"
echo " m: ${num_m}  * ${PRICE_M_MONTH} = ${cost_m} (E/month)"
echo " l: ${num_l}  * ${PRICE_L_MONTH} = ${cost_l} (E/month)"





