import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:user_repository/src/entities/entities.dart';
import 'package:user_repository/src/models/models.dart';
import 'package:user_repository/src/user_repo.dart';

class FirebaseUserRepo implements UserRepository {
  final FirebaseAuth _firebaseAuth;
  final userCollection = FirebaseFirestore.instance.collection("users");

  FirebaseUserRepo({
    FirebaseAuth? auth,
  }) : _firebaseAuth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> setUserData(user) async {
    try {
      await userCollection.doc(user.userId).set(user.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<MyUser> signUp(user, String password) async {
    try {
      final firebaseUser = await _firebaseAuth.createUserWithEmailAndPassword(
          email: user.email, password: password);
      user.userId = firebaseUser.user!.uid;
      return user;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Stream<MyUser?> get user {
    return _firebaseAuth.authStateChanges().flatMap((firebaseUser) async* {
      if (firebaseUser == null) {
        yield MyUser.empty;
      } else {
        yield await userCollection.doc(firebaseUser.uid).get().then((value) =>
            MyUser.fromEntity(MyUserEntity.fromDocument(value.data()!)));
      }
    });
  }
}
