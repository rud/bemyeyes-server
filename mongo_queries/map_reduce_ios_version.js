db.iphone_distributions.remove({})

db.devices.mapReduce(
    function() {
        var iosVersion = this.system_version.substring(10, 11);
        emit(this.model + iosVersion, {
            count: 1
        });
    },
    function(key, values) {
        var count = 0;

        values.forEach(function(v) {
            count += v['count'];;
        });

        return {
            count: count
        };
    }, {
        query: {},
        out: "iphone_distributions"
    }
)