sudo ballerina build ana_service.bal
sudo docker container rm target_ana_service_1

sudo cp docker-compose.yml target
sudo cp postgresql-42.2.5.jar target
sudo cp ballerina.conf target

cd target
sudo docker-compose build
sudo docker-compose up
