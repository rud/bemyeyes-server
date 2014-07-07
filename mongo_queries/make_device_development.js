db.devices.update(
   { device_token: "device_token" },
   {
      $set: { development: true },
   }
)