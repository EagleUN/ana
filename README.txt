Requirementes:
- Ballerina: https://ballerina.io/downloads/
- Docker: https://www.docker.com/

To build the image and generate the docker file run:

$ sudo ballerina build ana_service.bal

You can now see the Dockerfile in target/ana_service.
To run the project run:

$ sudo docker run -d -p 9090:9090 ana_service:latest