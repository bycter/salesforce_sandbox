public without sharing class ChatterService {

    public static void pushFeedItems(List<String> itemBodies, Id groupId) {
        List<FeedItem> feedItems = new List<FeedItem>();
        if (groupId != null) {
            for (String itemBody : itemBodies) {
                FeedItem post = new FeedItem();
                post.IsRichText = true;
                post.ParentId = groupId;
                post.Body = itemBody;

                feedItems.add(post);
            }
            insert feedItems;
        }
    }

    public static Id findChatterGroupByName(String groupName) {
        CollaborationGroup[] chatterGroup = [
                Select Id, g.Name
                From CollaborationGroup g
                where g.Name = :groupName
                limit 1
        ];
        return chatterGroup.size() != 0 ? chatterGroup.get(0).Id : null;
    }

}