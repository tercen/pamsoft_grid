# intro

https://pamgene.com/technology/


# Current usage


```smalltalk

anOperator := IDispatch progId: 'PamSoft_Grid4.analyze'
anOperator grdFromFile: anArrayLayoutFile.
aResult := anOperator analyzecycleserie: aListOfImagePath

```

pg_image_analysis/PamSoft_Grid/com/grdFromFile.m

https://github.com/tercen/pg_image_analysis/blob/1b3e191210987687c4ae5fa6d623499acef99f1c/PamSoft_Grid/com/grdFromFile.m

pg_image_analysis/PamSoft_Grid/com/analyzeimageseries.m

https://github.com/tercen/pg_image_analysis/blob/1b3e191210987687c4ae5fa6d623499acef99f1c/PamSoft_Grid/com/analyzeimageseries.m



# pamsoft_grid

What needs to be specified ?

- file format for input parameters
- file format for input data
- file format for output data
- commands line params

# Processing step

image pre-processing
griding
segmentation
quantification

# Instrument specific parameters

gridSpotPitch   17.0
qntSaturationLimit   4095

# Array layout

Row
Col
ID (is it required ?)
Xoff
Yoff

# Griding

```shell
pamsoft_grid --mode=grid --param-file=xxx --array-layout-file=xxx --images-list-file=xxx --output-file=xxx
```

# Segmentation + Quantification

Array layout

Row
Col
xFixedPosition
yFixedPosition

```shell
pamsoft_grid --mode=quantification --param-file=xxx --array-layout-file=xxx --images-list-file=xxx --output-file=xxx
```
