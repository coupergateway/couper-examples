FROM coupergateway/couper:latest

# copy base configuration
COPY *.hcl /conf/

# copy htpasswd file
COPY .htpasswd /conf/

# Switch to -f argument instead of -d
CMD [ "run", "-f", "/conf/couper.hcl" ]
