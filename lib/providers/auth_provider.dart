import 'package:flutter/material.dart';
import 'package:gym_management_app/models/user.dart';
import 'package:gym_management_app/services/supabase_service.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart'; // para el tipo AuthState

// Estados posibles de auth.
// recovering = el usuario abrió el link de "recuperar PIN" del email y
// tiene que elegir un PIN nuevo antes de entrar.
enum AuthStatus { checking, authenticated, unauthenticated, recovering }

class AuthProvider extends ChangeNotifier{
  //estado Interno ((privado))
  AuthStatus _status = AuthStatus.checking;
  UserModel? _user;
  String? _errorMessage;
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;


//Getters publico (solo lectura)
AuthStatus get status => _status;
UserModel? get user => _user;
String? get errorMessage => _errorMessage;
bool get isLoading => _isLoading;

//helpers de rol -  Los widgets los usan para decidir que mostrar
bool get isAdmin => _user?.workArea == WorkArea.admin;
bool get isProfesor => _user?.workArea == WorkArea.bigClass || _user?.workArea == WorkArea.smallClass;
bool get isAuthenticated => _status == AuthStatus.authenticated;
bool get isUnauthenticated => _status == AuthStatus.unauthenticated;
bool get isChecking => _status == AuthStatus.checking;
//Arrancar la app
//se llama una sola vez en el main
//verificar si hay una sesion guardada

AuthProvider(){
  _init();
}
// Se llama una sola vez al crear el provider (reemplaza a checkSavedSession)
void _init(){
// Escucha CUALQUIER cambio de sesión: login, logout, refresh de token,
    // e incluso sesión restaurada automáticamente al abrir la app.
  _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((data) async {
    // Supabase emite este evento cuando se abre el link de recuperación:
    // hay una sesión temporal, pero el usuario todavía no eligió PIN nuevo.
    if (data.event == AuthChangeEvent.passwordRecovery) {
      _status = AuthStatus.recovering;
      notifyListeners();
      return;
    }
    final session = data.session;
    if (session == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    await _loadProfile(session.user.id);
  }
  );
}

Future<void> _loadProfile(String userId) async{
  final result = await SupabaseService.getProfesorById(userId);
  if (result['success'] == true) {
    final loadedUser = result['profesor'] as UserModel;
    if(loadedUser.isActive){
      _user = loadedUser;
      _status = AuthStatus.authenticated;
    } else {
      await logout();
      return;
    }
  } else{
    _status = AuthStatus.unauthenticated;
  }
  notifyListeners();
}


  //Login 
  Future<bool> login(String username, String pin) async {
    _isLoading = true; 
    _errorMessage = null;
    notifyListeners();

    try{
      final result = await SupabaseService.loginUser(
        username: username,
        pin: pin,
      );
      if(result['success']== true){
        // No hace falta guardar sesión manual: onAuthStateChange
        // ya se dispara solo y actualiza _user y _status.
        final userData = result['user'] as Map<String, dynamic>;
        await _loadProfile(userData['id'] as String);

        _isLoading = false;
        notifyListeners();

        return _status == AuthStatus.authenticated;

     }else{
      _errorMessage = result['error'] ?? 'Credenciales invalidas';
      _isLoading = false;
      notifyListeners();
      return false;
    } 
  } catch (e){
    _errorMessage = 'Error de conexion. verifica tu internet.';
    _isLoading = false; 
    notifyListeners();
    return false;
  } 
}


// logout 
Future <void> logout() async {
  await SupabaseService.logoutUser();
  // onAuthStateChange va a disparar el evento y limpiar _user solo,
    // pero lo forzamos también acá por si acaso.
  _user = null;
  _status = AuthStatus.unauthenticated;
  _errorMessage = null;
  notifyListeners();
}

// Guarda el PIN nuevo después de abrir el link de recuperación.
// El PIN es la contraseña de Supabase Auth: Supabase la guarda hasheada,
// nosotros nunca la vemos ni la mandamos por email.
Future<bool> updatePin(String newPin) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();
  try {
    final res = await SupabaseService.client.auth
        .updateUser(UserAttributes(password: newPin));
    final userId = res.user?.id;
    if (userId == null) throw AuthException('Sin usuario');
    await _loadProfile(userId); // pasa a authenticated (o a login si está inactivo)
    return true;
  } on AuthException catch (e) {
    _errorMessage = e.message.contains('different')
        ? 'El PIN nuevo tiene que ser distinto al anterior'
        : 'No se pudo cambiar el PIN. Pedí un link nuevo.';
    return false;
  } catch (_) {
    _errorMessage = 'Error de conexión. Verificá tu internet.';
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

//Limpiar Error(al abrir Login util)
void clearError(){
  _errorMessage = null;
  notifyListeners();
}
@override
void dispose(){
  _authSubscription?.cancel();
  super.dispose();
}
}
