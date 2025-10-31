#https://github.com/tercen/operator_runtimes
FROM tercen/runtime-matlab-image:r2020b-bullseye

COPY standalone/pamsoft_grid /mcr/exe/pamsoft_grid
COPY standalone/run_pamsoft_grid.sh /mcr/exe/run_pamsoft_grid.sh
COPY standalone/pamsoft_grid_batch /mcr/exe/pamsoft_grid_batch
COPY standalone/run_pamsoft_grid_batch.sh /mcr/exe/run_pamsoft_grid_batch.sh