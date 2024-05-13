class UserrData {

  late final String? token;
  late final String? userName;
  late final String? imgSrc;
  late final String? email;
  late final List<String> roles;
  late final String? message;
  late final bool? error;
  late final bool? isLogin;
  late final bool? gender;
  late final String? area;
  late final String? gove;
  late final String? exToken;
  
  UserrData.fromJson(Map<String, dynamic> json){
    token = json['token']??'';
    userName = json['userName']??'';
    imgSrc = json['imgSrc']??'';
    email = json['email']??'';
    roles = List.castFrom<dynamic, String>(json['roles']);
    message = null;
    error = json['error'];
    isLogin = json['isLogin'];
    gender = json['gender'];
    area = json['area']??'';
    gove = json['gove']??'';
    exToken = json['exToken'];
  }

  
}