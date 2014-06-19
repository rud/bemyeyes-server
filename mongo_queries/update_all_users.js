var cnt = 1;
db.users.find().forEach(function(data) {
    db.users.update({_id:data._id},{$set:{id2:cnt}});
    cnt++;
});
