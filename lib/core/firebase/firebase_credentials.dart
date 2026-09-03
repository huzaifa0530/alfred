// core/firebase/firebase_credentials.dart
class FirebaseCredentials {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String storageBucket;

  const FirebaseCredentials({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.storageBucket,
  });

  Map<String, String> toJson() => {
        'apiKey': apiKey,
        'appId': appId,
        'messagingSenderId': messagingSenderId,
        'projectId': projectId,
        'storageBucket': storageBucket,
      };

  factory FirebaseCredentials.fromJson(Map<String, dynamic> json) {
    return FirebaseCredentials(
      apiKey: json['apiKey'] as String,
      appId: json['appId'] as String,
      messagingSenderId: json['messagingSenderId'] as String,
      projectId: json['projectId'] as String,
      storageBucket: json['storageBucket'] as String,
    );
  }
}