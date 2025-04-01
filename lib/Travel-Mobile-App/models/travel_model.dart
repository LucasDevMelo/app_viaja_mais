import 'package:firebase_database/firebase_database.dart';

class Comment {
  final String title;
  final String userImage;
  final String userName;
  final double rating;
  final String datetime;
  final String comment;

  Comment({
    required this.title,
    required this.userImage,
    required this.userName,
    required this.rating,
    required this.datetime,
    required this.comment,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      title: json['title'],
      userImage: json['userImage'],
      userName: json['userName'],
      rating: json['rating'].toDouble(),
      datetime: json['datetime'],
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'userImage': userImage,
      'userName': userName,
      'rating': rating,
      'datetime': datetime,
      'comment': comment,
    };
  }
}

class TravelDestination {
  final String id, name, description, location, hours, duration, age;
  final List<String> imageUrls;
  final List<Comment> comments;

  TravelDestination({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.imageUrls,
    required this.hours,
    required this.duration,
    required this.age,
    required this.comments,
  });

  factory TravelDestination.fromJson(Map<String, dynamic> json) {
    List<Comment> loadedComments = [];
    if (json['comments'] != null) {
      Map<dynamic, dynamic> commentsMap = json['comments'];
      loadedComments = commentsMap.entries
          .map((entry) => Comment.fromJson(Map<String, dynamic>.from(entry.value)))
          .toList();
    }

    return TravelDestination(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      imageUrls: List<String>.from(json['imageUrls']),
      hours: json['hours'],
      duration: json['duration'],
      age: json['age'],
      comments: loadedComments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'imageUrls': imageUrls,
      'hours': hours,
      'duration': duration,
      'age': age,
      'comments': {for (var comment in comments) comment.datetime: comment.toJson()},
    };
  }
}
