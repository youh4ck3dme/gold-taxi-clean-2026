// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventModel _$EventModelFromJson(Map<String, dynamic> json) => EventModel(
  id: (json['id'] as num).toInt(),
  date: BaseWordPressModel.parseDate(json['date']),
  title: BaseWordPressModel.parseRendered(json['title']),
  content: BaseWordPressModel.parseRendered(json['content']),
  excerpt: json['excerpt'] == null
      ? ''
      : BaseWordPressModel.parseRendered(json['excerpt']),
  embedded: json['_embedded'] as Map<String, dynamic>?,
  startDate: EventModel._parseDate(json['start_date']),
  endDate: EventModel._parseDate(json['end_date']),
  location: json['location'] as String?,
  latitude: EventModel._parseDouble(json['latitude']),
  longitude: EventModel._parseDouble(json['longitude']),
  category: json['category'] as String,
  images: json['images'] == null
      ? const []
      : EventModel._parseImages(json['images']),
  price: EventModel._parseDouble(json['price']),
);

Map<String, dynamic> _$EventModelToJson(EventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'title': instance.title,
      'content': instance.content,
      'excerpt': instance.excerpt,
      '_embedded': instance.embedded,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'category': instance.category,
      'images': instance.images,
      'price': instance.price,
    };
