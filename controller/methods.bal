import model;

type ControllerError error<string, map<anydata|error>>;

function buildError(string message) returns ControllerError {
    ControllerError e = error(message, { });
    return e;
}


public function insertFollow(string followerId, string followingId) returns ApiFollow|error {
    
    if ( model:insertFollow(followerId, followingId) )
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