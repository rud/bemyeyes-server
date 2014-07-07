db.tokens.find().forEach( function(myDoc) {
    var cursor = db.users.find({_id : ObjectId(myDoc.user_id)});
    if(cursor.hasNext() == false) {
        db.token.remove({_id : myDoc._id});
        print(myDoc._id)
    }
});