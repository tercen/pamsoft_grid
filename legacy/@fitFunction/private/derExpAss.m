function df = derExpAss(x, p)
Y0 = p(1);
Ys = p(2);
k = p(3);
df = k*Ys*exp(-k*x);
