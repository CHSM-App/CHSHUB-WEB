/*
 * The API host.
 *
 * Retrofit's @RestApi(baseUrl:) needs a compile-time constant, so this is a
 * const rather than something read at runtime. Swap the active line to point
 * the app at a different backend.
 *
 * Local backend (backend/app.js, PORT 8000):
 *   - Android emulator  -> 10.0.2.2 is the host machine; `localhost` inside the
 *                          emulator is the emulator itself and will not connect.
 *   - iOS simulator     -> localhost works, it shares the host network.
 *   - Physical device   -> use the machine's LAN address, e.g. 192.168.1.13.
 *
 * Plain http is already allowed by android:usesCleartextTraffic="true" in
 * android/app/src/main/AndroidManifest.xml.
 */
// Local backend — Chrome / iOS simulator / desktop:
// const String baseUrl = 'http://localhost:8000/';

// Local backend — Android emulator:
// const String baseUrl = 'http://10.0.2.2:8000/';

// Local backend — physical device on the same network:
// const String baseUrl = 'http://192.168.1.13:8000/';

// Production:
const String baseUrl = 'https://chshub.co.in/';
