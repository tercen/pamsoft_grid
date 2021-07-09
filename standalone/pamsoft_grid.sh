#!/bin/bash


#./pamsoft_grid.sh   --param-file=/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/input_test_1.json 

function usage() {
	echo "ERROR: $1."
	echo ""
	echo "pamsoft_grid.sh --param-file=PATH"
	echo ""
	echo "param-file:          path to a JSON file containing the configuration parameters."
	echo ""
}

export -f usage

# NEEDS to be set to wherever environment variable/path the Matlab Compiler Runtime is installed
MCR=$MCR_ROOT

#./run_pamsoft_grid.sh $MCR_ROOT "--mode=grid --param-file=xxx --array-layout-file=xxx --images-list-file=xxx --output-file=xxx"
# read the options

# Save last input argument just to make the parsing of arguments easier
for LAST_ARG; do true; done

PARAMFILE=



while [ "$1" != "" ]; do
	HASEQ=0
	if [[ "$1" == *"="* ]]; then
		IFS='=' read -ra ARGS <<< "$1"
		ARG=${ARGS[0]}
		VAL=${ARGS[1]}
		HASEQ=1
		unset IFS
	else
		ARG=$1
		VAL=$2
	fi

	case $ARG in
		

		--param-file)
		if [[ $HASEQ == 0 ]]; then
			shift
		fi

		PARAMFILE=$VAL

		# Keep parsing until we reach the end or the next argument
		# This is needed in case the parameter has spaces
		STOP=0

		while [ $STOP -eq 0 ]; do
			case $2 in
				--*) 
				STOP=1; 
				continue
				;;
				*[[:ascii:]] )
				PARAMFILE="${PARAMFILE} $2"
				if [[ "$2" = "$LAST_ARG" ]]; then
					STOP=1
				else
					shift
				fi 
				;;
				*)
				STOP=1
				;;
			esac
		done
		;;


		
	esac
	shift
done



if [[ -z ${PARAMFILE} ]] || [[ ! -f ${PARAMFILE} ]]; then
	usage "--param-file has not been set or file does not exist."

	exit 1
fi



./run_pamsoft_grid.sh $MCR "--param-file=${PARAMFILE}"











