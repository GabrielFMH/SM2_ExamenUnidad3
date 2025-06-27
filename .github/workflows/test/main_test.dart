import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:your_app/location_service.dart'; // Ajusta la importación según tu estructura

// Mocks generados manualmente
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

void main() {
  group('LocationService Tests', () {
    late LocationService locationService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockFirebaseFirestore mockFirebaseFirestore;
    late MockCollectionReference mockCollectionReference;
    late MockDocumentReference mockDocumentReference;
    late MockGeolocatorPlatform mockGeolocator;

    setUp(() {
      // Inicializar mocks
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockFirebaseFirestore = MockFirebaseFirestore();
      mockCollectionReference = MockCollectionReference();
      mockDocumentReference = MockDocumentReference();
      mockGeolocator = MockGeolocatorPlatform();

      // Configurar comportamiento de los mocks
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.email).thenReturn('test@example.com');
      when(mockFirebaseFirestore.collection('usuarios')).thenReturn(mockCollectionReference);
      when(mockCollectionReference.doc('test@example.com')).thenReturn(mockDocumentReference);
      when(mockDocumentReference.update(any)).thenAnswer((_) async => null);

      // Configurar Geolocator
      GeolocatorPlatform.instance = mockGeolocator;
      when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.denied);
      when(mockGeolocator.requestPermission()).thenAnswer((_) async => LocationPermission.whileInUse);
      when(mockGeolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      )).thenAnswer((_) async => Position(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          ));

      // Crear instancia de LocationService e inyectar mocks
      locationService = LocationService();
      locationService
        .._auth = mockFirebaseAuth
        .._firestore = mockFirebaseFirestore;
    });

    tearDown(() {
      reset(mockGeolocator);
    });

    test('registerAppEntry actualiza Firestore con usuario autenticado', () async {
      // Act
      await locationService.registerAppEntry();

      // Assert
      verify(mockDocumentReference.update({
        'ultimaEntradaApp': FieldValue.serverTimestamp(),
        'ultimoAcceso': FieldValue.serverTimestamp(),
      })).called(1);
    });

    test('registerAppEntry no hace nada sin usuario autenticado', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act
      await locationService.registerAppEntry();

      // Assert
      verifyNever(mockDocumentReference.update(any));
    });

    test('checkLocationPermission otorga permisos si inicialmente denegados', () async {
      // Act
      final hasPermission = await locationService._checkLocationPermission();

      // Assert
      expect(hasPermission, isTrue);
      verify(mockGeolocator.checkPermission()).called(1);
      verify(mockGeolocator.requestPermission()).called(1);
    });

    test('checkLocationPermission retorna false si permisos denegados permanentemente', () async {
      // Arrange
      when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.deniedForever);
      when(mockGeolocator.requestPermission()).thenAnswer((_) async => LocationPermission.deniedForever);

      // Act
      final hasPermission = await locationService._checkLocationPermission();

      // Assert
      expect(hasPermission, isFalse);
      verify(mockGeolocator.checkPermission()).called(1);
      verifyNever(mockGeolocator.requestPermission());
    });

    test('updateLocationOnce actualiza ubicación en Firestore', () async {
      // Act
      final result = await locationService.updateLocationOnce();

      // Assert
      expect(result, isTrue);
      verify(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      )).called(1);
      verify(mockDocumentReference.update({
        'ubicacionActual': {
          'latitud': 37.7749,
          'longitud': -122.4194,
          'precision': 10.0,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'ultimaUbicacionActualizacion': FieldValue.serverTimestamp(),
      })).called(1);
    });

    test('updateLocationOnce retorna false si no hay usuario autenticado', () async {
      // Arrange
      when(mockFirebaseAuth.currentUser).thenReturn(null);

      // Act
      final result = await locationService.updateLocationOnce();

      // Assert
      expect(result, isFalse);
      verifyNever(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      ));
      verifyNever(mockDocumentReference.update(any));
    });
  });
}