var express = require('express');
var db = require("./db")
var fs = require('fs-extra')
var router = express.Router();
var multer = require('multer');

const storage = multer.diskStorage({
  destination: function (req, file, cb) {

    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    cb(null, `${Date.now()}${file.originalname}`);
  }
});

//owner documents
const upload = multer({ storage: storage });
router.post('/OwnerDocuments', upload.array('docs', 10), function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var dirpath = __dirname + "/Documents/" + req.body.flat_id + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());

    db.query("insert into owner_documents (doc_path,doc_name,flat_id)values('https://app.chshub.co.in/upload/Documents/" + req.body.flat_id + "/" + (req.files.map(file => file.filename)).toString() + "','" + req.body.doc_name + "',"+ req.body.flat_id+")", function (err, result) {
      if (err)
        return res.status(500).json({ error: err.message });
      else {

        return res.status(200).json({ message: "Successfully" })
      }
    });


  }
});
router.get('/Documents/:id/:logo', async (req, res) => {
  res.sendFile(__dirname + "/Documents/" + req.params.id + "/" + req.params.logo);
});

router.get('/Documents/*', (req, res) => {
    const requestedPath = req.params[0]; // everything after /documents/

    // Prevent path traversal
    const safePath = path.normalize(requestedPath).replace(/^(\.\.[/\\])+/, '');

    // Full path on server
    const baseFolder = 'C:/Inetpub/vhosts/vengurlatech.com/chsmanagement/publish/Documents';
    const filePath = path.join(baseFolder, safePath);
	
  // Debug log
  console.log('📂 Trying to send file:', filePath);
    // Check if file exists
    if (!fs.existsSync(filePath)) {
        return res.status(404).send('File not found');
    }

    // Stream file
    res.sendFile(filePath);
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
    var dirpath = __dirname + "/ProductImages/" + req.body.product_id + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());

    db.query("insert into Product_Images (image_path,product_id)values('https://app.chshub.co.in/upload/ProductImages/" + req.body.product_id + "/" + (req.files.map(file => file.filename)).toString() + "'," + req.body.product_id + ")", function (err, result) {
      if (err)
        return res.status(500).json({ error: err.message });
      else {

        return res.status(200).json({ message: "Successfully" })
      }
    });


  }
});
router.get('/ProductImages/:id/:logo', async function(req, res)  {
  res.sendFile(__dirname + "/ProductImages/" + req.params.id + "/" + req.params.logo);
});



//HelpdeskRequest
router.post('/HelpdeskImages', upload.array('image', 10), function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var dirpath = __dirname + "/HelpdeskImages/" + req.body.helpdesk_id + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());

    db.query("insert into HelpdeskImages(active_status,documents,helpdesk_id)values(0,'https://app.chshub.co.in/upload/HelpdeskImages/" + req.body.helpdesk_id + "/" + (req.files.map(file => file.filename)).toString() + "'," + req.body.helpdesk_id + ")", function (err, result) {
      if (err)
        return res.status(500).json({ error: err.message });
      else {

        return res.status(200).json({ success: true, message: "Successfully" })
      }
    });


  }
});
router.get('/HelpdeskImages/:id/:logo',async function (req, res) {

  res.sendFile(__dirname + "/HelpdeskImages/" + req.params.id + "/" + req.params.logo);
});

router.post('/HelpdeskCommentImages', upload.array('images', 10), function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var dirpath = __dirname + "/HelpdeskImages/" + req.body.helpdesk_id + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());

    res.json({ image: "https://app.chshub.co.in/upload/HelpdeskImages/" + req.body.helpdesk_id + "/" + (req.files.map(file => file.filename)).toString() });
  }
});


//Family Member
router.post('/FamilyMembers', upload.array('files', 10), function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var dirpath = __dirname + "/FamilyMembers/" + req.body.flat + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else {
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }

    res.json({ image: "https://app.chshub.co.in/upload/FamilyMembers/" + req.body.flat + "/" + (req.files.map(file => file.filename)).toString() });
  }
});

router.get('/FamilyMembers/:id/:logo', async function(req, res)  {

  res.sendFile(__dirname + "/FamilyMembers/" + req.params.id + "/" + req.params.logo);
});



router.post('/StaffProfile', upload.array('image', 10), async function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var dirpath = __dirname + "/ProfileImages/" + req.body.staff_id + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    try {
      const result = await db.request()
        .input('operation', 'ProfileImage')
        .input('image',"https://app.chshub.co.in/upload/ProfilePhoto/" + req.body.staff_id + "/" + req.files.map(file => file.filename).toString())
        .input('staff_id', parseInt(req.body.staff_id, 10))
        .execute('[sp_staff_master]');
      return res.status(200).json({ success: true, message: "Successfully" })
    } catch (err) {
      res.status(500).json({ error: err.message });
    }

  }
});

// API to serve the uploaded profile image
router.get('/ProfilePhoto/:id/:file',async function (req, res)  {
  const filePath = __dirname + "/ProfileImages/" + req.params.id + "/" + req.params.file;
  res.sendFile(filePath, (err) => {
    if (err) {
      res.status(404).json({ error: "Image not found" });
    }
  });
});



// Profile Image Upload
router.post('/ProfilePhoto', upload.array('image', 10), async function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var dirpath = __dirname + "/ProfileImages/" + req.body.owner_id + "/"
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
        .input('profile_image',"https://app.chshub.co.in/upload/ProfilePhoto/" + req.body.owner_id + "/" + req.files.map(file => file.filename).toString())
        .input('owner_id', parseInt(req.body.owner_id, 10))
        .execute('sp_owner_master');
      return res.status(200).json({ success: true, message: "Successfully" })
    } catch (err) {
      res.status(500).json({ error: err.message });
    }

  }

});
// API to serve the uploaded profile image
router.get('/ProfilePhoto/:id/:file',async function (req, res)  {
  const filePath = __dirname + "/ProfileImages/" + req.params.id + "/" + req.params.file;
  res.sendFile(filePath, (err) => {
    if (err) {
      res.status(404).json({ error: "Image not found" });
    }
  });
});



//VISITOR PROFILE
router.post('/VisitorProfile', upload.array('image', 10), async function (req, res) {
  if (!req.files) {
    return res.status(500).json({ error: 'No file uploaded' });
  }
  else {
    var dirpath = __dirname + "/VisitorImage/" + req.body.visitor_id + "/"
    if (!fs.existsSync(dirpath)) {
      fs.mkdirSync(dirpath, { recursive: true });
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    }
    else
      fs.move('uploads/' + (req.files.map(file => file.filename)).toString(), dirpath + "/" + (req.files.map(file => file.filename)).toString());
    try {
      const result = await db.request()
        .input('operation', 'VisitorImage')
        .input('image',"https://app.chshub.co.in/upload/VisitorPhoto/" + req.body.visitor_id + "/" + req.files.map(file => file.filename).toString())
        .input('visitor_id', parseInt(req.body.visitor_id, 10))
        .execute('[sp_Visitor]');
		
		var imagePath = `https://app.chshub.co.in/upload/VisitorPhoto/${req.body.visitor_id}/${req.files.map(file => file.filename).toString()}`;
      return res.status(200).json({ success: true, message: imagePath })
    } catch (err) {
      res.status(500).json({ error: err.message });
    }

  }
});


// API to serve the uploaded profile image
router.get('/VisitorPhoto/:id/:file',async function (req, res)  {
  const filePath = __dirname + "/VisitorImage/" + req.params.id + "/" + req.params.file;
  res.sendFile(filePath, (err) => {
    if (err) {
      res.status(404).json({ error: "Image not found" });
    }
  });
});


module.exports = router;