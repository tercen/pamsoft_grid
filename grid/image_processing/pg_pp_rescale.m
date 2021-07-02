function params = pg_pp_rescale(params, rFactor)

if params.prpNSmallDisk > 0
    params.prpNSmallDisk = max(round(params.prpNSmallDisk * rFactor),1);
end
if params.prpNLargeDisk > 0
    params.prpNLargeDisk = max(round(params.prpNLargeDisk * rFactor),1);
end
if params.prpNCircle > 0
    params.prpNCircle = max(round(params.prpNCircle * rFactor),1);
end

