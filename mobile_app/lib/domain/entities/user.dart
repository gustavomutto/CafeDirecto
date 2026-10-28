// Entidades de usuarios y perfiles (finca del caficultor o empresa del comprador).
import 'bi.dart';

class RatingSummary {
  final double avg;
  final int count;
  const RatingSummary(this.avg, this.count);
  static const none = RatingSummary(0, 0);
}

class Review {
  final String by;
  final int stars;
  final Bi? text;
  final bool verified;
  const Review({required this.by, required this.stars, this.text, this.verified = false});
}

class AppUser {
  final int id;
  final String role; // 'farmer' | 'buyer'
  final String name;
  final String lang; // 'es' | 'en'
  final String? photo;
  final String email;
  final String phone;
  const AppUser({required this.id, required this.role, required this.name, required this.lang, this.photo, this.email = '', this.phone = ''});

  bool get isFarmer => role == 'farmer';

  AppUser withLang(String l) => AppUser(id: id, role: role, name: name, lang: l, photo: photo, email: email, phone: phone);
}

class FarmProfile {
  final int userId;
  final String producer;
  final String? producerPhoto;
  final String name, region, municipality;
  final int altitude;
  final double hectares;
  final List<String> varieties, processes, notes, certifications;
  final double sca;
  final int? since;
  final Bi story, quote;
  final String? cover;
  final List<String> gallery;
  final RatingSummary rating;
  final List<Review> reviews;

  const FarmProfile({
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
    required this.story,
    required this.quote,
    this.cover,
    required this.gallery,
    required this.rating,
    required this.reviews,
  });

  String get displayName => name.isNotEmpty ? name : producer;
}

class BuyerProfile {
  final int userId;
  final String contact;
  final String? contactPhoto;
  final String company, city, country, type, volume;
  final int? since;
  final Bi about, looking;
  final String? cover;
  final bool verified;
  final RatingSummary rating;
  final List<Review> reviews;

  const BuyerProfile({
    required this.userId,
    required this.contact,
    this.contactPhoto,
    required this.company,
    required this.city,
    required this.country,
    required this.type,
    required this.volume,
    this.since,
    required this.about,
    required this.looking,
    this.cover,
    required this.verified,
    required this.rating,
    required this.reviews,
  });

  String get displayName => company.isNotEmpty ? company : contact;
}

/// La sesión del usuario: sus datos y su perfil (uno de los dos según el rol).
class Account {
  final AppUser user;
  final FarmProfile? farm;
  final BuyerProfile? buyer;
  const Account(this.user, {this.farm, this.buyer});

  Account withLang(String l) => Account(user.withLang(l), farm: farm, buyer: buyer);
}

/// Datos para crear una cuenta.
class Registration {
  final String role, name, email, password, phone, lang;
  final String farmName, region, municipality; // caficultor
  final String company, city, country, type; // comprador
  const Registration({
    required this.role,
    required this.name,
    required this.email,
    required this.password,
    this.phone = '',
    required this.lang,
    this.farmName = '',
    this.region = '',
    this.municipality = '',
    this.company = '',
    this.city = '',
    this.country = '',
    this.type = '',
  });
}

/// Cambios a los datos de la cuenta (nombre, celular, idioma, foto).
class AccountUpdate {
  final String name, phone, lang;
  final int? photoId;
  const AccountUpdate({required this.name, required this.phone, required this.lang, this.photoId});
}

class FarmProfileUpdate {
  final String lang, name, region, municipality, story, quote, certifications;
  final int altitude;
  final double hectares, sca;
  final int? since, coverId;
  final List<String> varieties, processes, notes;
  final List<int> gallery;
  const FarmProfileUpdate({
    required this.lang,
    required this.name,
    required this.region,
    required this.municipality,
    required this.altitude,
    required this.hectares,
    required this.sca,
    this.since,
    required this.varieties,
    required this.processes,
    required this.notes,
    required this.story,
    required this.quote,
    required this.certifications,
    this.coverId,
    required this.gallery,
  });
}

class BuyerProfileUpdate {
  final String lang, company, city, country, type, volume, about, looking;
  final int? since, coverId;
  const BuyerProfileUpdate({
    required this.lang,
    required this.company,
    required this.city,
    required this.country,
    required this.type,
    required this.volume,
    this.since,
    required this.about,
    required this.looking,
    this.coverId,
  });
}
