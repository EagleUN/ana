import ballerina/http;
import ballerina/io;
import ballerina/config;

string RAPUNZEL_IP   = config:getAsString("RAPUNZEL_IP");
string RAPUNZEL_PORT = config:getAsString("RAPUNZEL_PORT"); 

http:Client rapunzelEndpoing = new(RAPUNZEL_IP + ":" + RAPUNZEL_PORT );

public function notifyFollow(string followerId, string followingId) {

    http:Request req = new;

    string path = "/users/" + followingId + "/followers/" + followerId;

    var resp = rapunzelEndpoing->post(path, req);

    if (resp is http:Response)
    {
        if ( resp.statusCode == 302 )
        {
            io:println("notifyFollow - successfully notified follow " + followerId + " -> " + followingId );
        }
        else
        {
            io:println("notifyFollow - rapunzel returned " + resp.statusCode + " status code for follow " + followerId + " -> " + followingId );
        }
    }
    else
    {
        io:println("notifyFollow - request failed for follow " +  followerId + " -> " + followingId + ": " + <string>resp.detail().message);
    }
}
