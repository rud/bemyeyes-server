query = {
    created_at: { // 2 minutes ago (from now)
        $gt: new Date(ISODate().getTime() - 1000 * 60 * 2)
    }
}

projection = {
    value: 1,
    created_at: 1,
}

db.requests.find(query, projection)
