# TODO: switch to latest with 1.9
FROM avenga/couper:edge

ARG HCL_FILE=couper.hcl

# copy base configuration
COPY couper.hcl /conf/couper.hcl
# copy environment base overlay configuration
COPY $HCL_FILE /conf/
