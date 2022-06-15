FROM avenga/couper:latest

# copy base configuration
COPY *.hcl /conf/

# Switch to -f argument instead of -d
CMD [ "run", "-f", "/conf/couper.hcl" ]
