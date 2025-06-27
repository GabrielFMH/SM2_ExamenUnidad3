import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Necesario para debugPrint
import 'package:your_app/location_service.dart'; // Ajusta la importación según tu estructura

// Mocks generados manualmente
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  group('LocationService - registerAppEntry', () {
    late LocationService locationService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirebaseFirestore;
    late MockCollectionReference mockCollectionReference;
    late MockDocumentReference mockDocumentReference;

    setUp(() {
      // Inicializar mocks
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirebaseFirestore = MockFirebaseFirestore();
      mockCollectionReference = MockCollectionReference();
      mockDocumentReference = MockDocumentReference();

      // Configurar comportamiento de los mocks
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn('test@example.com');
      when(mockFirebaseFirestore.collection('usuarios')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc('test@example.com')).thenReturn(mockDocumentReference);
      when(mockDocumentReference.update(any)).thenAnswer((_) async => null);

      // Crear instancia de LocationService e inyectar mocks
      locationService = LocationService();
      locationService
        .._auth = mockFirebaseAuth
        .._firestore = mockFirebaseFirestore;
    });

    test('Debe registrar la entrada cuando hay un usuario autenticado', () async {
      // Act
      await locationService.registerAppEntry();

      // Assert
      verify(mockDocumentReference.update({
        'ultimaEntradaApp': FieldValue.serverTimestamp(),
        'ultimoAcceso': FieldValue.serverTimestamp(),
      })).called(1);
    });

    test('No debe intentar registrar la entrada si no hay usuario autenticado', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act
      await locationService.registerAppEntry();

      // Assert
      verifyNever(mockDocumentReference.update(any));
    });

    test('Debe manejar errores al intentar registrar la entrada', () async {
      // Arrange
      when(mockDocumentReference.update(any)).thenThrow(Exception('Error simulado en Firestore'));

      // Act
      await locationService.registerAppEntry();

      // Assert
      // Verificamos que se intentó la actualización, pero no esperamos que falle la prueba
      verify(mockDocumentReference.update({
        'ultimaEntradaApp': FieldValue.serverTimestamp(),
        'ultimoAcceso': FieldValue.serverTimestamp(),
      })).called(1);
      // Nota: Como el código solo usa debugPrint para errores, no hay estado que verificar.
      // En un caso real, podrías querer propagar el error o manejarlo de forma verificable.
    });
  });
}
