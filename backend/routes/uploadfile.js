var express = require('express');
var db = require("./db")
var fs = require('fs-extra')
var router = express.Router();
var multer = require('multer');
var path = require('path');
var crypto = require('crypto');

/*
 * Upload limits.
 *
 * There were none: this router took any number of files of any type and any
 * size, from anyone (it was mounted without `protect`, which app.js now
 * applies). A single request could fill the disk, and nothing stopped a .js
 * or .exe being stored under a web-served directory.
 */
/*
 * Base URL stored in the database alongside each uploaded file. It was
 * written as a literal in six places, so moving domain would have needed a
 * data migration of every row already stored.
 */
// Where the .NET side stores society documents. Was a literal C:\Inetpub path.
const DOCUMENTS_ROOT = process.env.DOCUMENTS_ROOT ||
  'C:/Inetpub/vhosts/vengurlatech.com/chsmanagement/publish/Documents';

const PUBLIC_UPLOAD_BASE = process.env.PUBLIC_UPLOAD_BASE || 'https://chshub.co.in/upload';

const MAX_FILE_BYTES = Number(process.env.UPLOAD_MAX_BYTES || 10 * 1024 * 1024); // 10 MB
const MAX_FILES_PER_REQUEST = 10;

// Documents and images only. Anything executable or scriptable is refused.
const ALLOWED_MIME = new Set([
  'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic',
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
]);

const ALLOWED_EXT = new Set([
  '.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.pdf', '.doc', '.docx',
]);

const storage = multer.diskStorage({
  destination: function (req, file, cb) {

    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    /*
     * The name was `Date.now() + file.originalname`, and originalname comes
     * from the client. A file called "../../routes/db.js" therefore chose
     * where it landed, and two uploads in the same millisecond collided.
     * Nothing of the caller's string is kept but the extension.
     */
    const ext = path.extname(file.originalname || "").toLowerCase();
    const safeExt = ALLOWED_EXT.has(ext) ? ext : "";
    cb(null, `${Date.now()}-${crypto.randomBytes(8).toString("hex")}${safeExt}`);
  }
});

function fileFilter(req, file, cb) {
  const ext = path.extname(file.originalname || "").toLowerCase();
  // Both must pass: the declared type is the client's claim, the extension is
  // what the web server will serve the file as.
  if (ALLOWED_MIME.has(file.mimetype) && ALLOWED_EXT.has(ext)) return cb(null, true);
  const err = new Error(`Unsupported file type: ${file.originalname}`);
  err.code = 'LIMIT_UNEXPECTED_FILE';
  return cb(err);
}

//owner documents
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: { fileSize: MAX_FILE_BYTES, files: MAX_FILES_PER_REQUEST },
});

/*
 * Serve one stored file, and only from the directory it belongs to.
 *
 * These handlers built an absolute path by concatenating :id and :file and
 * passed it straight to res.sendFile. Route parameters arrive URL-decoded, so
 * a request for  /ProfilePhoto/1/..%2f..%2fdb.js  resolved to this directory
 * and returned the source of routes/db.js. res.sendFile only guards against
 * traversal when it is given a `root`, which none of them did.
 *
 * Passing a relative path plus `root` puts Express's own containment check
 * back in play; the explicit segment check rejects the obvious cases early
 * and keeps the failure a 404 rather than a 403 from deep inside Express.
 */
const path_ = path;
/*
 * The id that names the destination directory.
 *
 * Each upload handler builds its target as __dirname + "/<Kind>/" + an id
 * taken from the request body. Those ids are database keys and are always
 * numeric, but nothing checked: a flat_id of "../routes" put uploaded files
 * in the source directory. Rejecting anything but digits is the whole fix.
 */
function idSegment(value) {
  const s = String(value == null ? "" : value);
  return /^[0-9]{1,15}$/.test(s) ? s : null;
}

function sendStoredFile(res, subdir, segments) {
  const parts = segments.map((s) => String(s == null ? "" : s));

  // No separators, no traversal, nothing empty.
  const safe = parts.every((s) => s.length > 0 && !s.includes("/") && !s.includes("\\") && s !== "." && s !== "..");
  if (!safe) {
    return res.status(404).json({ error: "File not found" });
  }

  const root = path_.join(__dirname, subdir);
  return res.sendFile(path_.join(...parts), { root }, (err) => {
    if (err && !res.headersSent) {
      res.status(404).json({ error: "File not found" });
    }
  });
}
router.post('/OwnerDocuments', upload.array('docs', 10), function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var safeId = idSegment(req.body.flat_id);
    if (!safeId) {
      return res.status(400).json({ error: "flat_id must be numeric" });
    }
    var dirpath = __dirname + "/Documents/" + safeId + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());

        // doc_name came straight from the request body into the statement text.
    db.request()
      .input('doc_path', PUBLIC_UPLOAD_BASE + '/Documents/' + req.body.flat_id + '/' + (req.files.map(file => file.filename)).toString())
      .input('doc_name', req.body.doc_name)
      .input('flat_id', req.body.flat_id)
      .query('insert into owner_documents (doc_path,doc_name,flat_id) values (@doc_path,@doc_name,@flat_id)', function (err, result) {
      if (err)
        return res.status(500).json({ error: err.message });
      else {

        return res.status(200).json({ message: "Successfully" })
      }
    });


  }
});
router.get('/Documents/:id/:logo', async (req, res) => {
  return sendStoredFile(res, "Documents", [req.params.id, req.params.logo]);
});

router.get('/Documents/*', (req, res) => {
    // The document root was hardcoded to a C:\Inetpub path, which ties this
    // file to one server. The traversal guard was a hand-rolled normalize-and-
    // strip; res.sendFile with a `root` is checked by Express itself.
    const requestedPath = req.params[0];
    if (!requestedPath) return res.status(404).json({ error: 'File not found' });

    return res.sendFile(requestedPath, { root: DOCUMENTS_ROOT }, (err) => {
        if (err && !res.headersSent) {
            res.status(404).json({ error: 'File not found' });
        }
    });
});

// Owner Documents Upload
router.post('/OwnerDocuments', upload.array('docs', 10), async function (req, res) {
  if (!req.files || req.files.length === 0) {
    return res.status(500).json({ error: 'No file uploaded' });
  }

  try {
    const flatId = req.body.flat_id;
    const docName = req.body.doc_name;
    
    // Create directory path using BASE_DOCUMENTS_PATH
    const dirPath = path.join(BASE_DOCUMENTS_PATH, flatId.toString());
    
    // Ensure directory exists
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }

    // Move all uploaded files
    const movedFiles = [];
    for (const file of req.files) {
      const sourcePath = path.join('uploads', file.filename);
      const destPath = path.join(dirPath, file.filename);
      
      await fs.move(sourcePath, destPath, { overwrite: true });
      movedFiles.push(file.filename);
    }

    // Create public URLs for all files
    const fileUrls = movedFiles.map(filename => 
      `${PUBLIC_URL_BASE}/${flatId}/${filename}`
    );

    // Insert into database (adjust query based on your needs)
    const query = `INSERT INTO owner_documents (doc_path, doc_name, flat_id) VALUES (?, ?, ?)`;
    
    db.query(query, [fileUrls.join(','), docName, flatId], function (err, result) {
      if (err) {
        console.error('Database error:', err);
        return res.status(500).json({ error: err.message });
      }
      
      return res.status(200).json({ 
        message: "Successfully uploaded",
        files: movedFiles,
        urls: fileUrls
      });
    });

  } catch (error) {
    console.error('Upload error:', error);
    return res.status(500).json({ error: error.message });
  }
});

// Serve documents - Unified route for both app and website
router.get('/Documents/:id/:filename',async function (req, res)  {
  const { id, filename } = req.params;
  const filePath = path.join(BASE_DOCUMENTS_PATH, id, filename);
  
  console.log('📂 Requested file:', filePath);
  
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'File not found' });
  }
  
  res.sendFile(filePath);
});

// Wildcard route for complex paths (e.g., with owner names)
router.get('/Documents/*', async function (req, res)  {
  const requestedPath = req.params[0];
  
  // Prevent path traversal attacks
  const safePath = path.normalize(requestedPath).replace(/^(\.\.[/\\])+/, '');
  
  // Construct full file path
  const filePath = path.join(BASE_DOCUMENTS_PATH, safePath);
  
  console.log('📂 Wildcard route - Requested:', requestedPath);
  console.log('📂 Wildcard route - Resolved to:', filePath);
  
  // Check if file exists
  if (!fs.existsSync(filePath)) {
    console.log('❌ File not found:', filePath);
    return res.status(404).json({ error: 'File not found' });
  }
  
  // Send file
  res.sendFile(filePath);
});

router.post('/ProductImages', upload.array('image', 10), function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var safeId = idSegment(req.body.product_id);
    if (!safeId) {
      return res.status(400).json({ error: "product_id must be numeric" });
    }
    var dirpath = __dirname + "/ProductImages/" + safeId + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());

        db.request()
      .input('image_path', PUBLIC_UPLOAD_BASE + '/ProductImages/' + req.body.product_id + '/' + (req.files.map(file => file.filename)).toString())
      .input('product_id', req.body.product_id)
      .query('insert into Product_Images (image_path,product_id) values (@image_path,@product_id)', function (err, result) {
      if (err)
        return res.status(500).json({ error: err.message });
      else {

        return res.status(200).json({ message: "Successfully" })
      }
    });


  }
});
router.get('/ProductImages/:id/:logo', async function(req, res)  {
  return sendStoredFile(res, "ProductImages", [req.params.id, req.params.logo]);
});



//HelpdeskRequest
router.post('/HelpdeskImages', upload.array('image', 10), function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var safeId = idSegment(req.body.helpdesk_id);
    if (!safeId) {
      return res.status(400).json({ error: "helpdesk_id must be numeric" });
    }
    var dirpath = __dirname + "/HelpdeskImages/" + safeId + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());

        db.request()
      .input('documents', PUBLIC_UPLOAD_BASE + '/HelpdeskImages/' + req.body.helpdesk_id + '/' + (req.files.map(file => file.filename)).toString())
      .input('helpdesk_id', req.body.helpdesk_id)
      .query('insert into HelpdeskImages(active_status,documents,helpdesk_id) values (0,@documents,@helpdesk_id)', function (err, result) {
      if (err)
        return res.status(500).json({ error: err.message });
      else {

        return res.status(200).json({ success: true, message: "Successfully" })
      }
    });


  }
});
router.get('/HelpdeskImages/:id/:logo',async function (req, res) {

  return sendStoredFile(res, "HelpdeskImages", [req.params.id, req.params.logo]);
});

router.post('/HelpdeskCommentImages', upload.array('images', 10), function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var safeId = idSegment(req.body.helpdesk_id);
    if (!safeId) {
      return res.status(400).json({ error: "helpdesk_id must be numeric" });
    }
    var dirpath = __dirname + "/HelpdeskImages/" + safeId + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());

    res.json({ image: PUBLIC_UPLOAD_BASE + "/HelpdeskImages/" + req.body.helpdesk_id + "/" + (req.files.map(file => file.filename)).toString() });
  }
});


//Family Member
router.post('/FamilyMembers', upload.array('files', 10), function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var safeId = idSegment(req.body.flat);
    if (!safeId) {
      return res.status(400).json({ error: "flat must be numeric" });
    }
    var dirpath = __dirname + "/FamilyMembers/" + safeId + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else {
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }

    res.json({ image: PUBLIC_UPLOAD_BASE + "/FamilyMembers/" + req.body.flat + "/" + (req.files.map(file => file.filename)).toString() });
  }
});

router.get('/FamilyMembers/:id/:logo', async function(req, res)  {

  return sendStoredFile(res, "FamilyMembers", [req.params.id, req.params.logo]);
});



router.post('/StaffProfile', upload.array('image', 10), async function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var safeId = idSegment(req.body.staff_id);
    if (!safeId) {
      return res.status(400).json({ error: "staff_id must be numeric" });
    }
    var dirpath = __dirname + "/ProfileImages/" + safeId + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    try {
      const result = await db.request()
        .input('operation', 'ProfileImage')
        .input('image',PUBLIC_UPLOAD_BASE + "/ProfilePhoto/" + req.body.staff_id + "/" + req.files.map(file => file.filename).toString())
        .input('staff_id', parseInt(req.body.staff_id, 10))
        .execute('[sp_staff_master]');
      return res.status(200).json({ success: true, message: "Successfully" })
    } catch (err) {
      res.status(500).json({ error: err.message });
    }

  }
});

// API to serve the uploaded profile image
router.get('/ProfilePhoto/:id/:file', async function (req, res) {
  return sendStoredFile(res, "ProfileImages", [req.params.id, req.params.file]);
});



// Profile Image Upload
router.post('/ProfilePhoto', upload.array('image', 10), async function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var safeId = idSegment(req.body.owner_id);
    if (!safeId) {
      return res.status(400).json({ error: "owner_id must be numeric" });
    }
    var dirpath = __dirname + "/ProfileImages/" + safeId + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    try {
      const result = await db.request()
        .input('operation', 'ProfileImage')
        .input('login_type', req.body.loginType)
        .input('profile_image',PUBLIC_UPLOAD_BASE + "/ProfilePhoto/" + req.body.owner_id + "/" + req.files.map(file => file.filename).toString())
        .input('owner_id', parseInt(req.body.owner_id, 10))
        .execute('sp_owner_master');
      return res.status(200).json({ success: true, message: "Successfully" })
    } catch (err) {
      res.status(500).json({ error: err.message });
    }

  }

});
// API to serve the uploaded profile image
router.get('/ProfilePhoto/:id/:file', async function (req, res) {
  return sendStoredFile(res, "ProfileImages", [req.params.id, req.params.file]);
});



//VISITOR PROFILE
router.post('/VisitorProfile', upload.array('image', 10), async function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var safeId = idSegment(req.body.visitor_id);
    if (!safeId) {
      return res.status(400).json({ error: "visitor_id must be numeric" });
    }
    var dirpath = __dirname + "/VisitorImage/" + safeId + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    try {
      const result = await db.request()
        .input('operation', 'VisitorImage')
        .input('image',PUBLIC_UPLOAD_BASE + "/VisitorPhoto/" + req.body.visitor_id + "/" + req.files.map(file => file.filename).toString())
        .input('visitor_id', parseInt(req.body.visitor_id, 10))
        .execute('[sp_Visitor]');
		
		var imagePath = `${PUBLIC_UPLOAD_BASE}/VisitorPhoto/${req.body.visitor_id}/${req.files.map(file => file.filename).toString()}`;
      return res.status(200).json({ success: true, message: imagePath })
    } catch (err) {
      res.status(500).json({ error: err.message });
    }

  }
});


// API to serve the uploaded profile image
router.get('/VisitorPhoto/:id/:file', async function (req, res) {
  return sendStoredFile(res, "VisitorImage", [req.params.id, req.params.file]);
});


module.exports = router;