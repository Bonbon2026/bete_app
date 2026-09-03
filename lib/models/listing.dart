class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String listingType;
  final String neighborhood;
  final String? address;
  final String verificationStatus;
  final DateTime? lastVerifiedAt;
  final DateTime createdAt;
  final List<String> photoUrls;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.listingType,
    required this.neighborhood,
    this.address,
    required this.verificationStatus,
    this.lastVerifiedAt,
    required this.createdAt,
    required this.photoUrls,
  });

  factory Listing.fromMap(Map<String, dynamic> map, List<String> photoUrls) {
    return Listing(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      listingType: map['listing_type'] as String,
      neighborhood: map['neighborhood'] as String,
      address: map['address'] as String?,
      verificationStatus: map['verification_status'] as String? ?? 'unverified',
      lastVerifiedAt: map['last_verified_at'] != null
          ? DateTime.parse(map['last_verified_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      photoUrls: photoUrls,
    );
  }
}
