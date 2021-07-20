#https://github.com/tercen/operator_runtimes
FROM tercen/runtime-matlab-image:r2020b

COPY standalone/pamsoft_grid /mcr/exe/pamsoft_grid
