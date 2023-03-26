import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_chat/locator.dart';
import 'package:firebase_chat/providers/base_provider.dart';
import 'package:firebase_chat/services/shared_preferences_service.dart';
import 'package:firebase_chat/utils/constants/constants.dart';
import 'package:firebase_chat/utils/enums/src/firebaseauth_enums.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends BaseProvider {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // AuthProvider({
  //   required this.googleSignIn,
  //   required this.firebaseAuth,
  //   required this.firebaseFirestore,
  // });

  FirebaseAuthStatus _firebaseAuthStatus = FirebaseAuthStatus.uninitialized;
  FirebaseAuthStatus get firebaseAuthStatus => _firebaseAuthStatus;

  Future<FirebaseAuthStatus> googleLogIn() async {
    _isLoading = true;
    notifyListeners();

    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      User? firebaseUser =
          (await firebaseAuth.signInWithCredential(credential)).user;
      log(firebaseUser.toString());
      if (firebaseUser != null) {
        final QuerySnapshot result = await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
            .get();
        final List<DocumentSnapshot> document = result.docs;
        if (document.isEmpty) {
          firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(firebaseUser.uid)
              .set({
            'nickname': firebaseUser.displayName,
            'photoUrl': firebaseUser.photoURL,
            'id': firebaseUser.uid
          });
        }
        _firebaseAuthStatus = FirebaseAuthStatus.authenticated;
      } else {
        _firebaseAuthStatus = FirebaseAuthStatus.authenticateError;
      }
    } else {
      _firebaseAuthStatus = FirebaseAuthStatus.authenticateError;
    }
    notifyListeners();
    return _firebaseAuthStatus;
  }

  Future<FirebaseAuthStatus> emailLogIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      User? firebaseUser = (await firebaseAuth.signInWithEmailAndPassword(
              email: email, password: password))
          .user;
      // log(firebaseUser.toString());
      if (firebaseUser != null) {
        locator<SharedPreferencesService>().setUserUid(firebaseUser.uid);
        _firebaseAuthStatus = FirebaseAuthStatus.authenticated;
      } else {
        _firebaseAuthStatus = FirebaseAuthStatus.authenticateError;
      }
    } catch (e) {}

    notifyListeners();
    return _firebaseAuthStatus;
  }
}
