// Website API — file uploads.
//
// The legacy pages use asp:FileUpload for photos, ID proofs, agreements,
// helpdesk images, bill attachments and society documents. Files land under
// backend/uploads/<category>/ and the stored path is what goes into the SP.
//
// The mobile API has its own uploader (routes/uploadfile.js) writing to its own
// folders; this is deliberately separate so neither can disturb the other.
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const { exec, sql } = require('../lib/db');
const { ApiError, ok, asyncHandler } = require('../lib/http');
const { str, optionalStr, int, oneOf } = require('../lib/validate');
const { requireSociety } = require('../middleware/authenticate');

const router = express.Router();

// Categories are a fixed set: a caller-supplied folder name would allow writing
// outside the uploads tree.
const CATEGORIES = [
  // The profile modal in Site.Master wrote img/ProfilePic/owner_<id>.png.
  'profile-photos',
  'owner-photos',
  'owner-documents',
  'agreements',
  'police-verification',
  'staff',
  'vendor-bills',
  'society-documents',
  'helpdesk',
  'products',
];

const UPLOAD_ROOT = path.join(__dirname, '..', '..', 'uploads', 'web');

const storage = multer.diskStorage({
  destination(req, _file, cb) {
    const category = CATEGORIES.includes(req.params.category) ? req.params.category : null;
    if (!category) return cb(new Error('Unknown upload category'));
    const dir = path.join(UPLOAD_ROOT, category);
    fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename(_req, file, cb) {
    // Keep the extension, discard the caller's name — it is attacker-controlled.
    const ext = path.extname(file.originalname).slice(0, 10).replace(/[^.\w]/g, '');
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${ext}`);
  },
});

const ALLOWED = /^(image\/(jpeg|png|gif|webp)|application\/pdf)$/;

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024, files: 10 },
  fileFilter(_req, file, cb) {
    if (!ALLOWED.test(file.mimetype)) {
      return cb(new Error('Only JPEG, PNG, GIF, WebP and PDF files are accepted'));
    }
    cb(null, true);
  },
});

router.use(requireSociety);

/**
 * POST /uploads/:category
 * multipart/form-data, field name `files` (one or many).
 * Returns the stored paths for the caller to pass to the relevant SP.
 */
router.post(
  '/:category',
  (req, res, next) => {
    oneOf(req.params.category, 'category', CATEGORIES);
    next();
  },
  (req, res, next) => {
    upload.array('files', 10)(req, res, (err) => {
      if (err) return next(ApiError.badRequest(err.message));
      next();
    });
  },
  asyncHandler(async (req, res) => {
    const files = req.files ?? [];
    if (!files.length) throw ApiError.badRequest('No files were uploaded');

    const items = files.map((f) => ({
      originalName: f.originalname,
      storedName: f.filename,
      // Relative path — what goes in the database and is served back by GET below.
      path: `${req.params.category}/${f.filename}`,
      url: `/api/web/uploads/file/${req.params.category}/${f.filename}`,
      size: f.size,
      mimeType: f.mimetype,
    }));

    return ok(res, { items, count: items.length }, 201);
  }),
);

/** GET /uploads/file/:category/:filename — serve a stored file. */
router.get(
  '/file/:category/:filename',
  asyncHandler(async (req, res) => {
    const category = oneOf(req.params.category, 'category', CATEGORIES);
    const filename = str(req.params.filename, 'filename', { max: 255 });

    // Reject anything that could escape the category folder.
    if (filename.includes('/') || filename.includes('\\') || filename.includes('..')) {
      throw ApiError.badRequest('Invalid filename');
    }

    const full = path.join(UPLOAD_ROOT, category, filename);
    if (!full.startsWith(UPLOAD_ROOT) || !fs.existsSync(full)) {
      throw ApiError.notFound('File not found');
    }
    return res.sendFile(full);
  }),
);

/**
 * POST /uploads/owner-document — record an uploaded owner document.
 * Upload first, then call this with the returned path.
 */
router.post(
  '/record/owner-document',
  asyncHandler(async (req, res) => {
    const flatId = int(req.body?.flatId, 'flatId', { min: 1 });
    const docName = str(req.body?.docName, 'docName', { max: 255 });
    const docPath = str(req.body?.docPath, 'docPath', { max: 500 });

    const pool = await require('../lib/db').getPool();
    // owner_documents has no stored procedure of its own; the legacy page
    // inserts directly. document_id is an IDENTITY column.
    await pool
      .request()
      .input('flat_id', sql.Int, flatId)
      .input('doc_name', sql.VarChar(255), docName)
      .input('doc_path', sql.VarChar(500), docPath)
      .query(
        'INSERT INTO owner_documents (flat_id, doc_name, doc_path, upload_date) VALUES (@flat_id, @doc_name, @doc_path, GETDATE())',
      );

    return ok(res, { recorded: true }, 201);
  }),
);

/** POST /uploads/record/society-document — register a file in upload_doc. */
router.post(
  '/record/society-document',
  asyncHandler(async (req, res) => {
    await exec('sp_upload_doc', {
      operation: 'Update',
      file_id: { type: sql.Int, value: int(req.body?.fileId, 'fileId', { required: false, default: 0 }) },
      file_save_path: { type: sql.NVarChar(500), value: str(req.body?.filePath, 'filePath', { max: 500 }) },
      doc_name: { type: sql.NVarChar(20), value: str(req.body?.docName, 'docName', { max: 20 }) },
      Tag: { type: sql.NVarChar(20), value: optionalStr(req.body?.tag, 'tag', { max: 20 }) },
      Description: { type: sql.NVarChar(50), value: optionalStr(req.body?.description, 'description', { max: 50 }) },
      society_id: { type: sql.NVarChar(10), value: req.societyId },
    });
    return ok(res, { recorded: true }, 201);
  }),
);

module.exports = router;
