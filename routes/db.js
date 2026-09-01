// Loaded here as well as in app.js: this module reads process.env at require
// time, so it must not depend on who required it first.
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const mssql = require('mssql');

// Connection details come from the environment. They were hardcoded here —
// username, password, host and port — which put the production database
// credentials in every clone of the repository and in every commit of its
// history. See backend/.env.example for the variables to set.
function required(name) {
    const value = process.env[name];
    if (!value) {
        // Fail at boot with the missing name, rather than at the first query
        // with a login error that says nothing about the cause.
        throw new Error(`${name} is not set — see backend/.env.example`);
    }
    return value;
}

const sqlConfig = {
    user: required('DB_USER'),
    password: required('DB_PASSWORD'),
    server: required('DB_SERVER'),
    database: required('DB_NAME'),
    port: Number(process.env.DB_PORT || 1433),
    options: {
        encrypt: process.env.DB_ENCRYPT !== 'false',
        // Defaults to verifying the server certificate. It was unconditionally
        // true, which accepts any certificate and leaves the connection open to
        // interception. Set DB_TRUST_SERVER_CERT=true only for a local instance
        // with a self-signed certificate.
        trustServerCertificate: process.env.DB_TRUST_SERVER_CERT === 'true',
    },
};

// Create a connection pool *once*, and reuse it everywhere.
const db = new mssql.ConnectionPool(sqlConfig);

function connect() {
    db.connect(function (err) {
        if (err) {
            console.log(err);
            // Worker was recycled / DB was briefly unreachable — retry
            // instead of leaving `db` permanently disconnected, which
            // otherwise makes every request 500 until the process restarts.
            setTimeout(connect, 5000);
        } else {
            console.log("Connection Successful");
        }
    });
}
connect();

// mssql pools emit 'error' on lost connections; without a listener Node
// treats it as an unhandled exception. Reconnect so the pool recovers.
db.on('error', function (err) {
    console.log('SQL pool error:', err);
    if (!db.connected && !db.connecting) {
        connect();
    }
});

module.exports = db;
