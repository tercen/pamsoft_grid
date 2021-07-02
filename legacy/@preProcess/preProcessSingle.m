function preProcessSingle(p, src, dst)

I = imread(src);
I = ppFun(p, I);
imwrite(I, dst, 'compression', 'none');
