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
 *   - Physical device   -> use the machine's LAN address, e.g. 192.168.0.160.
 *
 * Plain http to a local host also needs the cleartext exception that
 * android/app/src/main/AndroidManifest.xml now carries (debug builds only).
 */
// Local backend — Chrome / iOS simulator / desktop:
const String baseUrl = 'http://localhost:8000/';

// Local backend — Android emulator:
// const String baseUrl = 'http://10.0.2.2:8000/';

// Local backend — physical device on the same network:
// const String baseUrl = 'http://192.168.0.160:8000/';

// Production:
// const String baseUrl = 'https://app.chshub.co.in/';

/// Every Secretary endpoint lives under the website API, which is mounted at
/// /api/web in backend/app.js. Kept separate from the mobile API (routes/) —
/// different auth scope, different response envelope.
const String webApiPrefix = 'api/web';
