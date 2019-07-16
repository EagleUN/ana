import model;
import ballerina/http;
import ballerina/config;
import ballerina/io;

type ControllerError error<string, map<anydata|error>>;

function buildError(string message) returns ControllerError {
    ControllerError e = error(message, { });
    return e;
}


public function insertFollow(string followerId, string followingId) returns ApiFollow|error {
    
    if ( model:insertFollow(followerId, followingId) == true)
    {
        return new ApiFollow(followerId, followingId);
    }
    else
    {
        return buildError("Could not insert into database");
    }
}

public function getFollowers(string userId) returns ApiUserIdList|error
{
    string[]|error r = model:getFollowers(userId);
    if ( r is error ) 
    {
        return r;
    }
    else
    {
        return new ApiUserIdList(r);
    }
}

public function getFollowing(string userId) returns ApiUserIdList|error
{
    string[]|error r = model:getFollowing(userId);
    if ( r is error )
    {
        return r;
    }
    else
    {
        return new ApiUserIdList(r);
    }
}

public function follows(string followerId, string followingId) returns boolean|error
{
    return model:follows(followerId, followingId);
}

public function deleteFollow(string followerId, string followingId) returns boolean|error
{
    return model:deleteFollow(followerId, followingId);
}


string VANELLOPE_IP   = config:getAsString("VANELLOPE_IP");
string VANELLOPE_PORT = config:getAsString("VANELLOPE_PORT"); 

http:Client vanellopeEndpoint = new(VANELLOPE_IP + ":" + VANELLOPE_PORT );

function buildApiOtherUserList ( string userId, json js ) returns ApiOtherUserList|error {
    ApiOtherUserList r = new();
    int|error totalUsers = int.convert(js["total"]);
    if ( totalUsers is error )
    {
        return buildError("total field in vanallope response must be an int");
    }
    else
    {
        var userList = js["list"];
        foreach int i in 0...totalUsers-1 {
            var otherUser = userList[i];
            if ( otherUser["uuid"] != userId ) {                
                var otherUserName = string.convert(otherUser["name"]);
                var otherUserLastName = string.convert(otherUser["last_name"]);
                var otherUserId = string.convert(otherUser["uuid"]);
                if ( otherUserName is error || otherUserLastName is error || otherUserId is error ) {
                    return buildError("Vanellope must return user's name, last_name and id for each each");
                }
                else {

                    ApiOtherUser u = new();    
                    u.name = otherUserName;
                    u.id = otherUserId;
                    u.lastName = otherUserLastName;
                    var iFollow = follows(userId, u.id);
                    var followsMe = follows(u.id, userId);
                    if ( iFollow is error )
                    {
                        return buildError ("Couldn't not determine follows relationship between " + userId + " and " + u.id + ". Message: " + <string>iFollow.detail().message );
                    }
                    else if ( followsMe is error ) {
                        return buildError ("Couldn't not determine follows relationship between " + userId + " and " + u.id + ". Message: " + <string>followsMe.detail().message );
                    }
                    else
                    {
                        u.iFollow = iFollow;
                        u.followsMe = followsMe;
                        r.otherUsers[r.count] = u;
                        r.count += 1;
                    }  
                }
            }
        }
    }
    return r;
}

public function getUsersListFor(string userId) returns ApiOtherUserList|error
{
    http:Request req = new;

     string path = "/signup/users";

     var resp = vanellopeEndpoint->get(path);

    if (resp is http:Response)
    {
        if ( resp.statusCode >= 200 && resp.statusCode < 300 )
        {
            io:println("getAllUsers from Vanellope sucessful" );
            var js = resp.getJsonPayload();
            if ( js is error )
            {
                return buildError("no json payload received from Vanellope");
            }
            else
            {
                io:println(js);
                return buildApiOtherUserList(userId, js);
            }
        }
        else
        {
            return buildError("getAllUsers from Vanellope failed - returned status code " + resp.statusCode);
        }
    }
    else
    {
        return buildError("getAllUsers from Vanellope failed with error message: " + <string>resp.detail().message);
    }
}
