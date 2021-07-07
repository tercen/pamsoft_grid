#!/bin/bash


#./pamsoft_grid.sh  --mode=$MODE --param-file=/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/input_test_1.json --array-layout-file=/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/631158404_631158405_631158406 86312 Array Layout.txt --images-list-file=/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/image_list_test_1.txt --output-file=/media/thiago/EXTRALINUX/Upwork/code/evolve_images/data1/output_test_1.txt

function usage() {
	echo "ERROR: $1."
	echo ""
	echo "pamsoft_grid.sh --mode=[grid|segmentation] --param-file=PATH --array-layout-file=PATH --images-list-file=PATH --output-file=PATH"
	echo ""
	echo "param-file:          path to a JSON file containing the configuration parameters."
	echo "array-layout-file:   path to a TXT file with information about the array layout."
	echo "images-list-file:    path to a TXT file containing a list of image paths, one image path per line."
	echo "output-file:         path to a TXT file where the results of the processing will be stored."
	echo ""
}

export -f usage

# NEEDS to be set to wherever environment variable/path the Matlab Compiler Runtime is installed
MCR=$MCR_ROOT

#./run_pamsoft_grid.sh $MCR_ROOT "--mode=grid --param-file=xxx --array-layout-file=xxx --images-list-file=xxx --output-file=xxx"
# read the options

# Save last input argument just to make the parsing of arguments easier
for LAST_ARG; do true; done

MODE=
PARAMFILE=
ARRAYLAYOUTFILE=
IMAGELISTSFILE=
OUTPUTFILE=



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
		--mode)
		if [[ $HASEQ == 0 ]]; then
			shift
		fi

		MODE=$VAL
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
				MODE="${MODE} ${2}"
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


		--array-layout-file)
		if [[ $HASEQ == 0 ]]; then
			shift
		fi

		ARRAYLAYOUTFILE=$VAL

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
				ARRAYLAYOUTFILE="${ARRAYLAYOUTFILE} $2"
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
		


		--images-list-file)
		if [[ $HASEQ == 0 ]]; then
			shift
		fi

		IMAGELISTSFILE=$VAL

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
				IMAGELISTSFILE="${IMAGELISTSFILE} $2"
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



		--output-file)
		if [[ $HASEQ == 0 ]]; then
			shift
		fi

		OUTPUTFILE=$VAL

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
				OUTPUTFILE="${OUTPUTFILE} $2"
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



MODE=${MODE^^}
# Check if all parameters have been set
if [[ -z $MODE ]]; then
    
	usage "--mode has not been set."
	exit 1
fi

if [[ -z ${PARAMFILE} ]] || [[ ! -f ${PARAMFILE} ]]; then
	usage "--param-file has not been set or file does not exist."

	exit 1
fi

if [[ -z ${ARRAYLAYOUTFILE} ]] || [[ ! -f ${ARRAYLAYOUTFILE} ]]; then
	usage "--array-layout-file has not been set or file does not exist."

	exit 1
fi

if [[ -z ${IMAGELISTSFILE} ]] || [[ ! -f ${IMAGELISTSFILE} ]]; then
	usage "--images-list-file has not been set or file does not exist."

	exit 1
fi

if [[ -z ${OUTPUTFILE} ]]; then
	usage "--output-file has not been set."
	exit 1
fi



./run_pamsoft_grid.sh $MCR "--mode=$MODE --param-file=${PARAMFILE} --array-layout-file=${ARRAYLAYOUTFILE} --images-list-file=${IMAGELISTSFILE} --output-file=${OUTPUTFILE}"











