#FROM tercen/matlab:r2020b-2 as builder
#
#COPY grid /mcr/grid
#COPY io /mcr/io
#COPY util /mcr/util
#COPY quantification /mcr/quantification
#COPY main /mcr/main
#COPY docker/build.m /mcr/docker/build.m
#
#WORKDIR /mcr/docker
#
#RUN bash -i -c "matlab -batch build"
#
#FROM tercen/mcr:R2020b
#
#COPY --from=builder /tmp/pamsoft_grid/pamsoft_grid /mcr/standalone/pamsoft_grid
#
#ENTRYPOINT /mcr/standalone/pamsoft_grid

#FROM tercen/mcr:R2020b

FROM tercen/runtime-matlab-image:r2020b

COPY standalone/pamsoft_grid /mcr/exe/pamsoft_grid
