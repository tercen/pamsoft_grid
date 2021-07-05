function s = annotatedSeries(clAnnotation);


dummyPoint = dataPoint([],[],[],[],[],[], [], [], []);
s.annotation = clAnnotation;
s.dataPoints = dummyPoint;
s.isempty = 1;

s = class(s, 'annotatedSeries');


