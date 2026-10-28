// DTOs de usuario y perfiles: reflejan el JSON del servidor y se convierten en entidades.
import '../../core/utils/json.dart';
import '../../domain/entities/bi.dart';
import '../../domain/entities/user.dart';

class BiDto {
  final String es, en;
  const BiDto(this.es, this.en);
  static BiDto? fromJson(dynamic j) => j is Map ? BiDto(asString(j['es']), asString(j['en'])) : null;
  Bi toEntity() => Bi(es, en);
}

class RatingSummaryDto {
  final double avg;
  final int count;
  const RatingSummaryDto(this.avg, this.count);
  factory RatingSummaryDto.fromJson(dynamic j) => j is Map ? RatingSummaryDto(asDouble(j['avg']), asInt(j['count'])) : const RatingSummaryDto(0, 0);
  RatingSummary toEntity() => RatingSummary(avg, count);
}

class ReviewDto {
  final String by;
  final int stars;
  final BiDto? text;
  final bool verified;
  const ReviewDto({required this.by, required this.stars, this.text, required this.verified});
  factory ReviewDto.fromJson(Map<String, dynamic> j) =>
      ReviewDto(by: asString(j['by']), stars: asInt(j['stars']), text: BiDto.fromJson(j['text']), verified: asBool(j['verified']));
  Review toEntity() => Review(by: by, stars: stars, text: text?.toEntity(), verified: verified);
}

class UserDto {
  final int id;
  final String role, name, lang, email, phone;
  final String? photo;
  const UserDto({required this.id, required this.role, required this.name, required this.lang, this.photo, required this.email, required this.phone});

  factory UserDto.fromJson(Map<String, dynamic> j) => UserDto(
        id: asInt(j['id']),
        role: asString(j['role']),
        name: asString(j['name']),
        lang: asString(j['lang']) == 'en' ? 'en' : 'es',
        photo: asStringOrNull(j['photo']),
        email: asString(j['email']),
        phone: asString(j['phone']),
      );

  AppUser toEntity() => AppUser(id: id, role: role, name: name, lang: lang, photo: photo, email: email, phone: phone);
}

class FarmProfileDto {
  final int userId, altitude;
  final int? since;
  final String producer, name, region, municipality;
  final String? producerPhoto, cover;
  final double hectares, sca;
  final List<String> varieties, processes, notes, certifications, gallery;
  final BiDto? story, quote;
  final RatingSummaryDto rating;
  final List<ReviewDto> reviews;

  const FarmProfileDto({
    required this.userId,
    required this.producer,
    this.producerPhoto,
    required this.name,
    required this.region,
    required this.municipality,
    required this.altitude,
    required this.hectares,
    required this.varieties,
    required this.processes,
    required this.notes,
    required this.certifications,
    required this.sca,
    this.since,
    this.story,
    this.quote,
    this.cover,
    required this.gallery,
    required this.rating,
    required this.reviews,
  });

  factory FarmProfileDto.fromJson(Map<String, dynamic> j) => FarmProfileDto(
        userId: asInt(j['userId']),
        producer: asString(j['producer']),
        producerPhoto: asStringOrNull(j['producerPhoto']),
        name: asString(j['name']),
        region: asString(j['region']),
        municipality: asString(j['municipality']),
        altitude: asInt(j['altitude']),
        hectares: asDouble(j['hectares']),
        varieties: asStringList(j['varieties']),
        processes: asStringList(j['processes']),
        notes: asStringList(j['notes']),
        certifications: asStringList(j['certifications']),
        sca: asDouble(j['sca']),
        since: asIntOrNull(j['since']),
        story: BiDto.fromJson(j['story']),
        quote: BiDto.fromJson(j['quote']),
        cover: asStringOrNull(j['cover']),
        gallery: asStringList(j['gallery']),
        rating: RatingSummaryDto.fromJson(j['rating']),
        reviews: asMapList(j['reviews']).map(ReviewDto.fromJson).toList(),
      );

  FarmProfile toEntity() => FarmProfile(
        userId: userId,
        producer: producer,
        producerPhoto: producerPhoto,
        name: name,
        region: region,
        municipality: municipality,
        altitude: altitude,
        hectares: hectares,
        varieties: varieties,
        processes: processes,
        notes: notes,
        certifications: certifications,
        sca: sca,
        since: since,
        story: story?.toEntity() ?? Bi.empty,
        quote: quote?.toEntity() ?? Bi.empty,
        cover: cover,
        gallery: gallery,
        rating: rating.toEntity(),
        reviews: reviews.map((r) => r.toEntity()).toList(),
      );
}

class BuyerProfileDto {
  final int userId;
  final int? since;
  final String contact, company, city, country, type, volume;
  final String? contactPhoto, cover;
  final BiDto? about, looking;
  final bool verified;
  final RatingSummaryDto rating;
  final List<ReviewDto> reviews;

  const BuyerProfileDto({
    required this.userId,
    required this.contact,
    this.contactPhoto,
    required this.company,
    required this.city,
    required this.country,
    required this.type,
    required this.volume,
    this.since,
    this.about,
    this.looking,
    this.cover,
    required this.verified,
    required this.rating,
    required this.reviews,
  });

  factory BuyerProfileDto.fromJson(Map<String, dynamic> j) => BuyerProfileDto(
        userId: asInt(j['userId']),
        contact: asString(j['contact']),
        contactPhoto: asStringOrNull(j['contactPhoto']),
        company: asString(j['company']),
        city: asString(j['city']),
        country: asString(j['country']),
        type: asString(j['type']),
        volume: asString(j['volume']),
        since: asIntOrNull(j['since']),
        about: BiDto.fromJson(j['about']),
        looking: BiDto.fromJson(j['looking']),
        cover: asStringOrNull(j['cover']),
        verified: asBool(j['verified']),
        rating: RatingSummaryDto.fromJson(j['rating']),
        reviews: asMapList(j['reviews']).map(ReviewDto.fromJson).toList(),
      );

  BuyerProfile toEntity() => BuyerProfile(
        userId: userId,
        contact: contact,
        contactPhoto: contactPhoto,
        company: company,
        city: city,
        country: country,
        type: type,
        volume: volume,
        since: since,
        about: about?.toEntity() ?? Bi.empty,
        looking: looking?.toEntity() ?? Bi.empty,
        cover: cover,
        verified: verified,
        rating: rating.toEntity(),
        reviews: reviews.map((r) => r.toEntity()).toList(),
      );
}

/// Respuesta de /me, /auth/login, etc.: { user, profile }.
class AccountDto {
  final UserDto user;
  final Map<String, dynamic>? profile;
  const AccountDto(this.user, this.profile);

  factory AccountDto.fromJson(Map<String, dynamic> j) => AccountDto(UserDto.fromJson(asMap(j['user'])), j['profile'] is Map ? asMap(j['profile']) : null);

  Account toEntity() {
    final u = user.toEntity();
    final p = profile;
    return Account(
      u,
      farm: u.isFarmer && p != null ? FarmProfileDto.fromJson(p).toEntity() : null,
      buyer: !u.isFarmer && p != null ? BuyerProfileDto.fromJson(p).toEntity() : null,
    );
  }
}

/// Respuesta de /auth/login y /auth/register: { token, user }.
class AuthResponseDto {
  final String token;
  const AuthResponseDto(this.token);
  factory AuthResponseDto.fromJson(Map<String, dynamic> j) => AuthResponseDto(asString(j['token']));
}

// ── DTOs de envío (entidad → JSON) ───────────────────────────────
class RegistrationDto {
  static Map<String, dynamic> toJson(Registration r) => {
        'role': r.role,
        'name': r.name,
        'email': r.email,
        'password': r.password,
        'phone': r.phone,
        'lang': r.lang,
        if (r.role == 'farmer') ...{'farmName': r.farmName, 'region': r.region, 'municipality': r.municipality},
        if (r.role == 'buyer') ...{'company': r.company, 'city': r.city, 'country': r.country, 'type': r.type},
      };
}

class AccountUpdateDto {
  static Map<String, dynamic> toJson(AccountUpdate u) => {'name': u.name, 'phone': u.phone, 'lang': u.lang, 'photoId': u.photoId};
}

class FarmProfileUpdateDto {
  static Map<String, dynamic> toJson(FarmProfileUpdate f) => {
        'lang': f.lang,
        'name': f.name,
        'region': f.region,
        'municipality': f.municipality,
        'altitude': f.altitude,
        'hectares': f.hectares,
        'sca': f.sca,
        'since': f.since,
        'varieties': f.varieties,
        'processes': f.processes,
        'notes': f.notes,
        'story': f.story,
        'quote': f.quote,
        'certifications': f.certifications,
        'coverId': f.coverId,
        'gallery': f.gallery,
      };
}

class BuyerProfileUpdateDto {
  static Map<String, dynamic> toJson(BuyerProfileUpdate b) => {
        'lang': b.lang,
        'company': b.company,
        'city': b.city,
        'country': b.country,
        'type': b.type,
        'volume': b.volume,
        'since': b.since,
        'about': b.about,
        'looking': b.looking,
        'coverId': b.coverId,
      };
}
