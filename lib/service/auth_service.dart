import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '771842050756-e2t1342s690a3papahmm1qgjcvaocmdp.apps.googleusercontent.com'
  );

  User? get currentUser => _auth.currentUser;

  // Login email & password
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      return UserModel.fromMap(
        doc.data() as Map<String, dynamic>,
        result.user!.uid,
      );
    } catch (e) {
      print('LOGIN ERROR: $e');
      return null;
    }
  }

  // Register email & password
  Future<UserModel?> register(String nama, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel user = UserModel(
        uid: result.user!.uid,
        nama: nama,
        email: email,
        role: 'pelanggan',
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(user.toMap());

      return user;
    } catch (e) {
      return null;
    }
  }

  // Login dengan Google
  Future<UserModel?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancel

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result =
          await _auth.signInWithCredential(credential);

      // Cek apakah user sudah pernah login sebelumnya
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (!doc.exists) {
        // User baru → simpan ke Firestore
        UserModel userBaru = UserModel(
          uid: result.user!.uid,
          nama: result.user!.displayName ?? 'Pelanggan',
          email: result.user!.email ?? '',
          role: 'pelanggan',
        );
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userBaru.toMap());
        return userBaru;
      } else {
        // User lama → ambil data dari Firestore
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>,
          result.user!.uid,
        );
      }
    } catch (e) {
      print('GOOGLE LOGIN ERROR: $e');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}