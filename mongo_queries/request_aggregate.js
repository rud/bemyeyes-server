db.devices.aggregate({
    $group: {
        _id: "$system_version",
        count: {
            $sum: 1
        }
    }
}, {
    $match: {
        count: {
            $gte: 5
        }
    }
})