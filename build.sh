
IMAGENAME="ghislain/germlinevarcalldockercsv:latest"

echo "---- Create the Docker image ${IMAGENAME} ----"
docker build --rm -t ${IMAGENAME} .
