import ballerina/http;
import ballerina/io;
import ballerinax/docker;
import ballerina/grpc;

const string ERROR_NO_FOLLOWING_ID_IN_JSON = "Payload should contain a JSON with a string followingId";

const string FOLLOWING_ID = "followingId";
const string FOLLOWER_ID = "followerId";

function buildErrorJson ( int code, string message ) returns json {
    json errorJson = { "message" : message, "code": code };
    return errorJson;
}

@docker:Config {}
@docker:Expose {}
listener http:Listener cmdListener = new(9090);

@http:ServiceConfig {
    basePath: "/ana"
}
service ana on cmdListener {

    # 
    # /users/{followerId}/following
    @http:ResourceConfig {
        methods: ["POST"],
        path: "users/{"+FOLLOWER_ID+"}/following"
    }
    resource function postFollow(http:Caller caller, http:Request request, string followerId) {
        http:Response response = new;
        json responseJson = {};

        json|error payload = request.getJsonPayload();

        if ( payload is error )
        {
            responseJson = buildErrorJson(400, ERROR_NO_FOLLOWING_ID_IN_JSON);
        }
        else
        {
            json followingId = payload[FOLLOWING_ID];
            if ( followingId is string )
            {
                //TODO: insert it to database and check if it's ok
                responseJson = { };
                responseJson[FOLLOWER_ID] = followerId;
                responseJson[FOLLOWING_ID] = followingId;
            }
            else
            {
                responseJson = buildErrorJson(400, ERROR_NO_FOLLOWING_ID_IN_JSON);
            }
        }
    
        response.setJsonPayload(untaint responseJson);

        error? result = caller -> respond(response);
        if ( result is error) {
            io:println("Error in responding", result);
        }
    }


}