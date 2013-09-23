var events = db.events.find()

while (events.hasNext()) {
    var event = events.next();

    var c = db.sessions.find({'event': event["slug"]}).count();

    db.events.update({slug: event['slug']}, {$set: {count: c}});
 }
