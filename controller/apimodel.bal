public type ApiFollow object {
    public string followerId;
    public string followingId;

    public function __init(string followerId, string followingId) {
        self.followerId = followerId;
        self.followingId = followingId;
    }
};

public type ApiUserIdList object {
    public int count;
    public string[] userIds;

    public function addUserId(string userId) {
        self.userIds[self.count] = userId;
        self.count += 1;
    }

    public function __init(string[] userIds) {
        self.count = userIds.length();
        self.userIds = userIds;
    }
};