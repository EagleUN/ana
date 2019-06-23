sudo rm -rf docker
sudo ballerina build ana_service.bal

sudo docker-compose build
sudo docker-compose up
