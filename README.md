# Build matlab image

```shell
docker run -it -d --name matlab -p 5901:5901 -p 6080:6080 --shm-size=512M mathworks/matlab:r2020b -vnc
# http://localhost:6080
# sudo matlab
# install matlab Compiler addon and Image_Processing_Toolbox and Statistics_and_Machine_Learning_Toolbox

docker commit matlab tercen/matlab:r2020b-4
docker rm -f matlab
```

# Compile component

```shell
 
docker run -it --rm \
      -v $PWD/docker/startup.m:/opt/matlab/R2020b/toolbox/local/startup.m \
      -v $PWD/grid:/pamsoft_grid/grid \
      -v $PWD/io:/pamsoft_grid/io \
      -v $PWD/util:/pamsoft_grid/util \
      -v $PWD/standalone:/pamsoft_grid/standalone \
      -v $PWD/quantification:/pamsoft_grid/quantification \
      -v $PWD/main:/pamsoft_grid/main \
      -v $PWD/docker:/pamsoft_grid/docker \
      --entrypoint=/bin/bash \
      -w /pamsoft_grid/docker \
       tercen/matlab:r2020b-4 \
       -i -c "matlab -batch build"
```       
# Build docker

```shell
docker build -t tercen/pamsoft_grid .
``` 

# Run gridding

```shell

# sudo rm test/output/output.txt
# clean up output if necessary
# sudo rm test/output/output.txt 
 
docker run --rm \
      -v $PWD/test:/test \
      tercen/pamsoft_grid:latest \
      /mcr/exe/pamsoft_grid \
      --param-file=/test/input/input_params.json
```           
# Run quantification

```shell
docker run --rm \
      -e "DISPLAY=:0" -v /tmp/.X11-unix:/tmp/.X11-unix \
      -v $PWD/standalone:/mcr/exe \
      -v $PWD/test:/test \
      tercen/mcr:R2020b \
      /mcr/exe/pamsoft_grid \
      --param-file=/test/input/input_params_quant.json
```

# Instrument specific parameters

gridSpotPitch   21.5

qntSaturationLimit   4095

# Comparison of images used for gridding and segmentation modes

Selected images in grid & quantification modes must have identical filenames (regardless of path and extension)

