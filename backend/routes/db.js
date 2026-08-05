const mssql = require('mssql');

const sqlConfig = {
    user: 'chsadmin',      // Replace with your username
    password:  'chs_admin@123',//'@x8#H8$?hEQJU',   // Replace with your password
    server: 'winsome.grabweb.in' ,        // Replace with your server
    database: 'Society',
   port:5691,
      // Replace with your database
    options: {
        encrypt: true, // Use this if you're on Windows Azure
        trustServerCertificate: true // Change to true for local dev / self-signed certs
    }
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
