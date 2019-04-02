# Auth070

## 1.1.0
 Mar. 21, 2019  
- inspired by Joe Birch's FlutterOAuth library
- introduced signInWithFacebook, signInWithTwitter, signInWithGithub, signInWithInstagram, 
- fireBaseUser() has _setUserFromFireBase(user); _photoUrl = user?.providerData[0]?.photoUrl ?? ''; 
- Included Joan Boon's signature_method.dart

## 1.0.1
 Mar. 07, 2019  
- import 'package:flutter/material.dart';

## 1.0.0
 Mar. 07, 2019  
- Added signInWithCredential, linkWithCredential, fetchSignInMethodsForEmail
- Concrete dependencies assigned firebase_auth: "0.7.0" google_sign_in: "3.2.4"
- **Breaking Change** Removed signInWithFacebook, signInWithTwitter, signInWithGoogle, 
- **Breaking Change** linkWithEmailAndPassword, linkWithGoogleCredential, linkWithFacebookCredential

## 0.1.1 
 Jan. 17, 2019  
- await _setFireBaseUserFromGoogle(currentUser);

## 0.1.0 
 Dec. 10
- Change semantic version number to convey development phase.

## 0.0.3
- await _user?.reload();

## 0.0.2
- Format code with dartfmt

## 0.0.1 
- Initial github release