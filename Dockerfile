#https://github.com/tercen/operator_runtimes
FROM tercen/runtime-matlab-image:r2020b-2

COPY standalone/pamsoft_grid /mcr/exe/pamsoft_grid
