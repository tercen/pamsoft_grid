function hFig = graphOut(r,sr, iOut, strID);
hFig = figure;

set(gcf, 'Name', ['Global QC using: ', strID]);
subplot(2,1,1)
hold off
errorbar(r, sr, 'k.-')
hold on
plot(find(iOut), r(iOut), 'r.');
ax0;
subplot(2,2,3)
hold off
x = [0:0.1:2];
cnt = hist(r, x);

h = bar(x, cnt);
hold on
set(h, 'facecolor', 'g');
cnt = hist(r(iOut), x);
h = bar(x, cnt);
set(h, 'facecolor', 'r');
cvAll       = std(r)/mean(r);
cvFilter    = std(r(~iOut))/mean(r(~iOut));
str = ['CV: ',num2str(cvAll), ' / ', num2str(cvFilter)];
title(str, 'interpreter','none');




