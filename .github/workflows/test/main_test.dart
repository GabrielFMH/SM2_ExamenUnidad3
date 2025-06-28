import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import '../../../lib/services/location_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  late LocationService locationService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirestore mockFirestore;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestore = MockFirestore();

    // Configurar Firestore mocks
    final mockCollection = MockCollectionReference();
    final mockDoc = MockDocumentReference();
    when(mockFirestore.collection('usuarios')).thenReturn(mockCollection);
    when(mockCollection.doc(any)).thenReturn(mockDoc);
    when(mockDoc.update(any)).thenAnswer((_) async => null);

    // Configurar FirebaseAuth mocks
    final mockUser = MockUser();
    when(mockUser.email).thenReturn('usuario@test.com');
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

    // Inicializar servicio con dependencias simuladas
    locationService = LocationService();
    locationService._auth = mockFirebaseAuth;
    locationService._firestore = mockFirestore;
  });

  test('startLocationTracking debería iniciar el seguimiento', () async {
    // Simular permisos concedidos y servicios habilitados
    when(Geolocator.checkPermission()).thenAnswer((_) async => LocationPermission.always);
    when(Geolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);

    final result = await locationService.startLocationTracking();

    expect(result, true);
    expect(locationService.isTracking, true);
    verify(mockFirestore.collection('usuarios').doc('usuario@test.com').update(any)).called(2); // app entry + location update
  });
}