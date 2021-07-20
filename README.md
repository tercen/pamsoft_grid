# Build matlab image

```shell
docker run -it -d --name matlab -p 5901:5901 -p 6080:6080 --shm-size=512M mathworks/matlab:r2020b -vnc
# http://localhost:6080
# sudo matlab
# install matlab compile and image toolbox
# 
docker commit matlab tercen/matlab:r2020b-4
docker rm -f matlab
```

# Compile component

```shell
docker run -it --rm \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v $PWD/grid:/mcr/grid \
      -v $PWD/io:/mcr/io \
      -v $PWD/util:/mcr/util \
      -v $PWD/standalone:/mcr/standalone \
      -v $PWD/quantification:/mcr/quantification \
      -v $PWD/main:/mcr/main \
      -v $PWD/docker:/mcr/docker \
      --entrypoint=/bin/bash \
      -w /mcr/docker \
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

