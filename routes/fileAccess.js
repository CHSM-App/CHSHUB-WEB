/*
 * Resident document access.
 *
 * This router previously served two things to anyone who could reach the host,
 * with no token required (app.js mounted it bare, and it now sits behind
 * `protect`):
 *
 *   GET /file/fileshow/:owner_id
 *       Streamed any owner's ID proof or agreement, keyed on a sequential id.
 *       Counting from 1 walked the entire society's identity documents.
 *
 *   GET /file/*
 *       Sent any file under __dirname — this very directory. GET /file/db.js
 *       returned the source containing the database password, and
 *       GET /file/serviceAccountKey.json returned the Firebase private key.
 *       Its traversal guard only compared the joined path against the base, so
 *       it stopped ../ but was never meant to stop what it actually served.
 *
 * The wildcard handler is gone. It had no legitimate use: the documents it was
 * supposed to expose live on the other host, reached through getFiles.ashx
 * below, not in the backend's own source directory.
 *
 * fileshow now requires a token AND that the record belongs to the caller.
 */
const express = require('express');
const axios = require("axios");
const db = require("./db");

const app = express();

// The host holding the uploaded documents. Was hardcoded twice in this file.
const FILE_HOST = process.env.FILE_HOST || 'https://chshub.co.in';

/*
 * The owner row must belong to the caller.
 *
 * The mobile token carries the number the resident logged in with, so the row
 * is matched on it. Compared on the last ten digits because the app may send a
 * country code where owner_master stores the number bare, and a mismatch there
 * would lock residents out of their own documents rather than fail safe.
 */
async function ownerFileFor(ownerId, callerMobile) {
    const result = await db.request()
        .input('owner_id', ownerId)
        .input('mobile', String(callerMobile || ''))
        .query(
            'SELECT id_proof, agreement_path FROM owner_master ' +
            ' WHERE owner_id = @owner_id ' +
            '   AND (RIGHT(pre_mob, 10) = RIGHT(@mobile, 10) ' +
            '     OR RIGHT(alter_mob, 10) = RIGHT(@mobile, 10))',
        );
    return result.recordset && result.recordset.length ? result.recordset[0] : null;
}

app.get("/fileshow/:owner_id", async (req, res) => {
    try {
        const callerMobile = req.user && req.user.mobile;
        if (!callerMobile) {
            return res.status(401).json({ error: "Not authenticated" });
        }

        const row = await ownerFileFor(req.params.owner_id, callerMobile);

        // Same answer whether the owner does not exist or belongs to someone
        // else, so this cannot be used to probe which ids are real.
        if (!row) {
            return res.status(404).json({ error: "Owner not found" });
        }

        const filePath = row.id_proof;
        if (!filePath) {
            return res.status(404).json({ error: "No document on file" });
        }

        // Convert DB format -> safe URL format
        const encodedPath = encodeURIComponent(String(filePath).replace(/\\/g, "/"));
        const fileURL = `${FILE_HOST}/getFiles.ashx?path=${encodedPath}`;

        const response = await axios.get(fileURL, {
            responseType: "arraybuffer",
            timeout: 30000,
        });

        res.set("Content-Type", response.headers["content-type"] || "application/octet-stream");
        res.set("Content-Disposition", response.headers["content-disposition"] || "inline");
        return res.send(response.data);
    } catch (err) {
        console.error("File access error:", err.message);
        return res.status(500).json({ error: "Unable to load file" });
    }
});

module.exports = app;
