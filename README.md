
# Running the code

Compilation command

```shell
mcc -m pamsoft_grid.m -d /path/to/standalone -o pamsoft_grid -R -nodisplay

```
 
From the standalone folder
```shell
./../pamsoft_grid.sh  --mode=grid --param-file=input_test_1.json --array-layout-file=631158404_631158405_631158406 86312 Array Layout.txt --images-list-file=image_list_test_1.txt --output-fileoutput_test_1.txt
```



```

```shell
# Compilation using docker image, TODO 
docker run -it --rm \
      -v $PWD:/pamsoft_grid \
      mathworks/matlab:r2021a
      bash
   
```


```shell
# Get matlab runtime
docker pull tercen/mcr:R2020b

docker run --rm -ti \
      -v $PWD/standalone/:/mcr/exe/ \
      tercen/mcr:R2020b \
      bash
      
# Run

# clean up output if necessary
# sudo rm test/output/output.txt

# For compilation, though it raises an error (cannot find some compiler libs)
docker run --rm \
      -v $PWD/grid:/mcr/grid \
      -v $PWD/io:/mcr/io \
      -v $PWD/util:/mcr/util \
      -v $PWD/standalone:/mcr/standalone \
      -v $PWD/quantification:/mcr/quantification \
      -v $PWD/main:/mcr/main \
      -v $PWD/docker:/mcr/docker \
      tercen/mcr:R2020b \
      /mcr/docker/compile_docker 
 
docker run --rm \
      -v $PWD/standalone:/mcr/exe \
      -v $PWD/test:/test \
      tercen/mcr:R2020b \
      /mcr/exe/pamsoft_grid \
      --param-file=/test/input/input_params.json

# IF graphics are needed

docker run --rm \
      -v $PWD/standalone:/mcr/exe \
      -v $PWD/test:/test \
      -e "DISPLAY=:0" -v /tmp/.X11-unix:/tmp/.X11-unix \
      tercen/mcr:R2020b \
      /mcr/exe/pamsoft_grid \
      --param-file=/test/input/input_params.json



```

```shell
# Compilation using docker image, TODO 
docker run -it --rm \
      -v $PWD:/pamsoft_grid \
      mathworks/matlab:r2021a
      bash
   
```


# intro

https://pamgene.com/technology/


# Current usage


```smalltalk

anOperator := IDispatch progId: 'PamSoft_Grid4.analyze'
anOperator grdFromFile: anArrayLayoutFile.
aResult := anOperator analyzecycleserie: aListOfImagePath

```

pg_image_analysis/PamSoft_Grid/com/grdFromFile.m

https://github.com/tercen/pg_image_analysis/blob/1b3e191210987687c4ae5fa6d623499acef99f1c/PamSoft_Grid/com/grdFromFile.m

pg_image_analysis/PamSoft_Grid/com/analyzeimageseries.m

https://github.com/tercen/pg_image_analysis/blob/1b3e191210987687c4ae5fa6d623499acef99f1c/PamSoft_Grid/com/analyzeimageseries.m



# pamsoft_grid

What needs to be specified ?

- file format for input parameters
- file format for input data
- file format for output data
- commands line params

# Processing step

image pre-processing

griding



segmentation

quantification


# Instrument specific parameters

gridSpotPitch   21.5
qntSaturationLimit   4095

# Array layout

Row
Col
Xoff
Yoff

reference spot have negative row and col

# Griding

```shell
pamsoft_grid --mode=grid --param-file=xxx --array-layout-file=xxx --images-list-file=xxx --output-file=xxx
```

# Segmentation + Quantification

Array layout

Row
Col
xFixedPosition
yFixedPosition

```shell
pamsoft_grid --mode=quantification --param-file=xxx --array-layout-file=xxx --images-list-file=xxx --output-file=xxx
```