sudo rm -rf docker
sudo ballerina build ana_service.bal

# sudo cp docker-compose.yml docker
# sudo cp postgresql-42.2.5.jar target
# sudo cp ballerina.conf target

#cd docker
sudo docker-compose build
sudo docker-compose up
