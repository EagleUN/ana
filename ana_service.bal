import ballerina/http;
import ballerina/io;
import ballerinax/docker;
import controller;

const string ERROR_NO_FOLLOWING_ID_IN_JSON = "Payload should contain a JSON with a string followingId";
const string ERROR_FAILED_TO_INSERT_RECORD = "Failed to insert the follow in the database";
const string INTERNAL_DATABASE_ERROR = "Internal error related to DB";

#API names for url parameters
const string USER_ID = "userId";
const string OTHER_USER_ID = "otherUserId";

#API names for JSON responses
const string FOLLOWER_ID = "followerId";
const string FOLLOWING_ID = "followingId";

function buildErrorJson ( string message ) returns json {
    json errorJson = { "message" : message};
    return errorJson;
}

function sendResponse(http:Caller caller, http:Response response) {
    error? result = caller -> respond(response);
    if ( result is error) {
        io:println("Error in responding", result);
    }
}

function sendErrorResponse(http:Caller caller, int code, json errorJson) {
    http:Response response = new;
    response.statusCode = code;
    response.setPayload(untaint errorJson);
    sendResponse(caller, response);
    
}

function sendOKResponse(http:Caller caller, json res) {
    http:Response response = new;
    response.setJsonPayload(untaint res);
    sendResponse(caller, response);
}

@docker:Config {}
@docker:Expose {}
listener http:Listener cmdListener = new(9090);

@http:ServiceConfig {
    basePath: "/ana"
}
service ana on cmdListener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "users/{"+USER_ID+"}/following"
    }
    resource function postFollow(http:Caller caller, http:Request request, string userId)
    {
        json|error payload = request.getJsonPayload();

        if ( payload is error ) {
            sendErrorResponse(caller, 400, buildErrorJson(ERROR_NO_FOLLOWING_ID_IN_JSON));
        }
        else
        {
            json followingId = payload[FOLLOWING_ID];
            if ( followingId is string ) {
                controller:ApiFollow|error r = controller:insertFollow(userId, followingId);
                if (r is error) {
                    sendErrorResponse(caller, 400, buildErrorJson(ERROR_FAILED_TO_INSERT_RECORD));
                }
                else {
                    json res = { };
                    res[FOLLOWER_ID] = r.followerId;
                    res[FOLLOWING_ID] = r.followingId;
                    sendOKResponse(caller, res);
                }
            }
            else {
                sendErrorResponse(caller, 400, buildErrorJson(ERROR_NO_FOLLOWING_ID_IN_JSON));
            }
        }
    }
    
    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{" + USER_ID + "}/followers"
    }
    resource function getFollowers(http:Caller caller, http:Request request, string userId)
{
        controller:ApiUserIdList|error r = controller:getFollowers(userId);
        if ( r is error )
        {
            sendErrorResponse(caller, 400, buildErrorJson(ERROR_NO_FOLLOWING_ID_IN_JSON) );
        }
        else {    
            json res = {
                "count": r.count,
                "userIds": r.userIds
            };      
            sendOKResponse(caller, res);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{"+USER_ID+"}/following"
    }
    resource function getFollowing(http:Caller caller, http:Request request, string userId)
    {
        controller:ApiUserIdList|error r = controller:getFollowing(userId);
        if ( r is error )
        {
            sendErrorResponse(caller, 400, buildErrorJson(ERROR_NO_FOLLOWING_ID_IN_JSON) );
        }
        else
        {
            json res = {
                "count": r.count,
                "userIds": r.userIds
            };
            sendOKResponse(caller, res);
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "users/{" + USER_ID + "}/following/{" + OTHER_USER_ID + "}"
    }
    resource function deleteFollow(http:Caller caller, http:Request request, string userId, string otherUserId )
    {        
        boolean|error r = controller:deleteFollow(userId, otherUserId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, INTERNAL_DATABASE_ERROR);
        }
        else
        {
            sendOKResponse(caller, {});
        }
    }

    # Checks if a given user follows another one. Returns:
    #    - 200 (OK) if the first user follows the second one. 
    #    - 204 (No content) if the first user does not follow the second one.
    #    - 500 (Internal error) in case something goes wrong.
    # + caller - The caller
    # + request - The request
    # + userId - ID of the user that follows
    # + otherUserId - ID of the user being followed
    @http:ResourceConfig {
        methods: ["GET"],
        path: "users/{" + USER_ID + "}/following/{" + OTHER_USER_ID + "}"
    }
    resource function getFollow(http:Caller caller, http:Request request, string userId, string otherUserId )
    {
        boolean|error r = controller:follows(userId, otherUserId);
        if ( r is error )
        {
            sendErrorResponse(caller, 500, INTERNAL_DATABASE_ERROR);
        }
        else
        {
            if ( r )
            {
                sendOKResponse(caller, {});
            }
            else
            {
                http:Response response = new;
                response.statusCode = 204;
                sendResponse(caller, response);
            }
            
        }
    }

}
