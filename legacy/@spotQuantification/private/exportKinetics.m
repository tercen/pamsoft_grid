function exportKinetics(q, fBase, xas)


fidsig          =   fopen([fBase,'Sig.dat'], 'wt');
fidbg           =   fopen([fBase,'Bg.dat'], 'wt');
fidsigmbg       =   fopen([fBase,'SigmBg.dat'], 'wt'); 


if fidsig == -1 || fidbg == -1 || fidsigmbg ==  -1
    error(['Could not open a file for ',fBase]);
end
% write line with hdr
[nRows, nCols, nCycles] = size(q);
fprintf(fidsig      ,'%s\t', '@cycles');
fprintf(fidbg       ,'%s\t', '@cycles');
fprintf(fidsigmbg   ,'%s\t', '@cycles');
for i=1:nRows
    for j=1:nCols
        spotID = get(q(i,j), 'ID');
        aRow = get(q(i,j), 'arrayRow');
        aCol = get(q(i,j), 'arrayCol');
        spotID = char(spotID);
        id = [spotID,'_(',num2str(aCol),':',num2str(aRow),')'];
        fprintf(fidsig, '%s\t', id);
        fprintf(fidbg, '%s\t', id);
        fprintf(fidsigmbg, '%s\t', id);
    end
end
fprintf(fidsig, '\n');
fprintf(fidbg, '\n');
fprintf(fidsigmbg, '\n');

for n = 1:nCycles
    fprintf(fidsig, '%d\t', xas(n));
    fprintf(fidbg, '%d\t', xas(n));
    fprintf(fidsigmbg, '%d\t', xas(n));

    [sig, bg, sigmbg] = getSignals(q(:,:,n), 'median');
    for  i = 1:nRows
        for j=1:nCols
            fprintf(fidsig, '%f\t', sig(i,j));
            fprintf(fidbg, '%f\t', bg(i,j));
            fprintf(fidsigmbg, '%f\t', sigmbg(i,j));
        end
    end
    fprintf(fidsig, '\n');
    fprintf(fidbg, '\n');
    fprintf(fidsigmbg, '\n');
end
fclose(fidsig);
fclose(fidbg);
fclose(fidsigmbg);

    



