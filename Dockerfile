#https://github.com/tercen/operator_runtimes
FROM tercen/runtime-matlab-image:r2020b-1

COPY standalone/pamsoft_grid /mcr/exe/pamsoft_grid
COPY standalone/run_pamsoft_grid.sh /mcr/exe/run_pamsoft_grid.sh
