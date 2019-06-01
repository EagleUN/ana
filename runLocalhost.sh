sudo ballerina build ana_service.bal

sudo cp docker-compose.yml target
sudo cp postgresql-42.2.5.jar target
sudo cp ballerina.conf target

cd target
sudo ballerina run ana_service.balx
