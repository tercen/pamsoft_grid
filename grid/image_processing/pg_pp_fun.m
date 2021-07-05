function Ipp = pg_pp_fun(params, I)
% Ipp = ppFun1(I, par)
% Image preprocessing filter
% par(1) = nSmallDisk, if > 0 size of small disk element (pix) for morph.
% open (small artifact removal)
% par(2) = nLargeDisk, if > 0 size of large disk element (pix) for tophat
% filter (reduction of bg/halo etc.)
% par(3) = nLpf, if > 0 size of lpf filter (pix)
% par(4) = nRoiDiam, if > 0, size of circular mask imposed on image

nSmallDisk   = params.prpNSmallDisk;
nLargeDisk   = params.prpNLargeDisk;
nRoiDiam     = params.prpNCircle;

Ipp = I;
if nSmallDisk > 0
    se  = strel('Disk', nSmallDisk);
    Ipp = imerode(Ipp, se);
    Ipp = imdilate(Ipp, se);
end

% nSmallDisk
if nLargeDisk > 0
    se  = strel('Disk', nLargeDisk);
    Io  = imerode(Ipp, se);
    Io  = imdilate(Io, se);
    Ipp = imsubtract(Ipp, Io);
end



% nLargeDisk
% imagesc(I); figure; imagesc(Ipp);
if nRoiDiam > 0
    [xc,yc] =  pg_circle(size(Ipp)/2, nRoiDiam/2, pi*nRoiDiam);
    Ipp     =  immultiply(Ipp,roipoly(Ipp, xc, yc));   
end

switch class(I)
    case 'uint8'
        Ipp = uint8(Ipp);
        bDepth = 256;
    case 'double'
        Ipp = double(Ipp);
        bDepth = 1;
    case 'uint16'
        Ipp = uint16(Ipp);
        bDepth = 2^16;
end



switch params.prpContrast
    case 'equalize'
        % contrast equalization (prevent very bright spots from causing the
        % gridding mask to be mislaid
        Ipp = histeq(Ipp);
    case 'co-equalize'
        % contrats equalization, equilization after contrast enhancement
        % (more robust to failure for arrays with weak spots)
        % get backgroundlevel by mode
        bin = 0:double(max(Ipp(:)));
        
        cnt = hist(Ipp(:), bin);
        [mx, imx] = max(cnt); bgLevel = bin(imx);
        % get 0.99 quantile
  
        q99 = quantile(Ipp(:), 0.99);
       
        % if the adjust step fails, refer to equalize:
        try 
            Ipp = imadjust(Ipp, [bgLevel, double(q99)]/bDepth);
            
            Ipp = histeq(Ipp);
        catch err
            err
            Ipp = histeq(Ipp);
        end
end

% imagesc(Ipp);
%EOF