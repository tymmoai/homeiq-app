class ServicesData {
  static List<Map<String, dynamic>> getLifestyleServices() {
    return [
      {
        'name': 'Cab',
        'image': 'lib/asset_img/cab_service.jpg',
        'hasFlow': true,
        'serviceType': 'Cab Booking',
        'route': '/service-flow/lifestyle',
      },
      {
        'name': 'Restaurant',
        'image': 'lib/asset_img/restaurant _service.jpg',
        'hasFlow': true,
        'serviceType': 'Restaurant Reservations',
        'route': '/service-flow/lifestyle',
      },
      {
        'name': 'Hotel',
        'image': 'lib/asset_img/hotel_service.jpg',
        'hasFlow': true,
        'serviceType': 'Hotel Booking',
        'route': '/service-flow/lifestyle',
      },
      {
        'name': 'Healthcare',
        'image': 'lib/asset_img/healthcare_service.jpg',
        'hasFlow': true,
        'serviceType': 'Healthcare Appointments',
        'route': '/service-flow/lifestyle',
      },
    ];
  }

  static List<Map<String, dynamic>> getHomeServices() {
    return [
      {
        'name': 'Assembly',
        'image': 'lib/asset_img/Assembly.png',
        'hasFlow': true,
        'route': '/service-flow/assembly',
      },
      {
        'name': 'Mounting',
        'image': 'lib/asset_img/Mounting.png',
        'hasFlow': true,
        'route': '/service-flow/mounting',
      },
      {
        'name': 'Moving',
        'image': 'lib/asset_img/Moving.png',
        'hasFlow': true,
        'route': '/service-flow/moving',
      },
      {
        'name': 'Cleaning',
        'image': 'lib/asset_img/Cleaning.png',
        'hasFlow': true,
        'route': '/service-flow/cleaning',
      },
      {
        'name': 'Outdoor Help',
        'image': 'lib/asset_img/Outdoor_Help.png',
        'hasFlow': true,
        'route': '/service-flow/outdoor',
      },
      {
        'name': 'Home Repairs',
        'image': 'lib/asset_img/Home_Repairs.png',
        'hasFlow': true,
        'route': '/service-flow/home-repairs',
      },
      {
        'name': 'Painting',
        'image': 'lib/asset_img/Painting.png',
        'hasFlow': true,
        'route': '/service-flow/painting',
      },
      {
        'name': 'Security',
        'image': 'lib/asset_img/Security.png',
        'hasFlow': true,
        'route': '/service-flow/security',
      },
    ];
  }
}
