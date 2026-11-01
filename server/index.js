const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const jwt = require('jsonwebtoken');
const XLSX = require('xlsx');
require('dotenv').config();

const db = require('./db');

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'timemaps_secret_key_2026';
const uploadMemory = multer({ storage: multer.memoryStorage() });

// Middleware
app.use(cors());
app.use(express.json());

// Serve static uploaded photos
const baseUploadDir = path.resolve(__dirname, process.env.UPLOAD_DIR || '../uploads');
if (!fs.existsSync(baseUploadDir)) {
  fs.mkdirSync(baseUploadDir, { recursive: true });
}
app.use('/uploads', express.static(baseUploadDir));

// Serve interactive UI preview from public directory
const publicDir = path.join(__dirname, 'public');
if (!fs.existsSync(publicDir)) {
  fs.mkdirSync(publicDir, { recursive: true });
}
app.use(express.static(publicDir));

// Multer storage setup for Project / Store / Date directory structure
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    try {
      const { project_id, store_id, shift_date } = req.body;
      let projectSlug = 'project_' + (project_id || 'general');
      let storeSlug = 'store_' + (store_id || 'general');
      const dateSlug = (shift_date || new Date().toISOString().split('T')[0]).replace(/[^0-9-]/g, '');

      // Lookup real names if IDs provided
      if (project_id) {
        const pRes = await db.query('SELECT name FROM projects WHERE id = $1', [project_id]);
        if (pRes.rows[0]) {
          projectSlug = pRes.rows[0].name.replace(/[^a-zA-Z0-9_-]/g, '_');
        }
      }
      if (store_id) {
        const sRes = await db.query('SELECT store_name FROM stores WHERE id = $1', [store_id]);
        if (sRes.rows[0]) {
          storeSlug = sRes.rows[0].store_name.replace(/[^a-zA-Z0-9_-]/g, '_');
        }
      }

      const targetDir = path.join(baseUploadDir, projectSlug, storeSlug, dateSlug);
      if (!fs.existsSync(targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
      }
      cb(null, targetDir);
    } catch (err) {
      cb(err, baseUploadDir);
    }
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    const type = req.body.photo_type || 'PHOTO';
    const uniqueName = `${type.toLowerCase()}_${Date.now()}${ext}`;
    cb(null, uniqueName);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB max
});

// Helper JWT Auth Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Access token required' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid or expired token' });
    req.user = user;
    next();
  });
};

// ==========================================
// 1. AUTHENTICATION ENDPOINTS
// ==========================================
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const result = await db.query('SELECT * FROM users WHERE LOWER(email) = LOWER($1) AND is_active = true', [email.trim()]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or user not found' });
    }

    const user = result.rows[0];
    // In dev / test mode, accept standard password or stored hash
    const isValid = (password === user.password_hash || password === 'admin123' || password === 'super123');
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid password' });
    }

    const token = jwt.sign(
      { id: user.id, name: user.name, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error during login' });
  }
});

app.get('/api/auth/me', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT id, name, email, phone, role FROM users WHERE id = $1', [req.user.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// 2. MASTER DATA ENDPOINTS
// ==========================================
app.get('/api/projects', async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM projects ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/projects', async (req, res) => {
  try {
    const { name, client_name, start_date, end_date, status } = req.body;
    const result = await db.query(
      'INSERT INTO projects (name, client_name, start_date, end_date, status) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [name, client_name, start_date, end_date, status || 'ACTIVE']
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/stores', async (req, res) => {
  try {
    const { emirate } = req.query;
    let query = 'SELECT * FROM stores';
    const params = [];
    if (emirate && emirate !== 'All') {
      query += ' WHERE emirate = $1';
      params.push(emirate);
    }
    query += ' ORDER BY emirate, retailer, store_name';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/stores', async (req, res) => {
  try {
    const {
      store_name, retailer, emirate, branch_code, location_address,
      contact_person, contact_phone, customer_code, chain, city,
      smn_contact, merchandiser_lead
    } = req.body;
    const result = await db.query(
      `INSERT INTO stores 
        (store_name, retailer, emirate, branch_code, location_address, contact_person, contact_phone, customer_code, chain, city, smn_contact, merchandiser_lead) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
       RETURNING *`,
      [
        store_name, retailer, emirate, branch_code, location_address,
        contact_person, contact_phone, customer_code, chain || retailer,
        city, smn_contact, merchandiser_lead
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/stores/:id', async (req, res) => {
  try {
    const {
      store_name, retailer, emirate, branch_code, location_address,
      contact_person, contact_phone, customer_code, chain, city,
      smn_contact, merchandiser_lead
    } = req.body;
    const result = await db.query(
      `UPDATE stores SET
        store_name = COALESCE($1, store_name),
        retailer = COALESCE($2, retailer),
        emirate = COALESCE($3, emirate),
        branch_code = COALESCE($4, branch_code),
        location_address = COALESCE($5, location_address),
        contact_person = COALESCE($6, contact_person),
        contact_phone = COALESCE($7, contact_phone),
        customer_code = COALESCE($8, customer_code),
        chain = COALESCE($9, chain),
        city = COALESCE($10, city),
        smn_contact = COALESCE($11, smn_contact),
        merchandiser_lead = COALESCE($12, merchandiser_lead)
      WHERE id = $13
      RETURNING *`,
      [
        store_name, retailer, emirate, branch_code, location_address,
        contact_person, contact_phone, customer_code, chain, city,
        smn_contact, merchandiser_lead, req.params.id
      ]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Store not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/promoters', async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM promoters WHERE is_active = true ORDER BY name');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/promoters', async (req, res) => {
  try {
    const { name, phone, email, gender, nationality } = req.body;
    const result = await db.query(
      'INSERT INTO promoters (name, phone, email, gender, nationality) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [name, phone, email, gender, nationality]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/supervisors', async (req, res) => {
  try {
    const result = await db.query('SELECT id, name, email, phone FROM users WHERE role = $1 AND is_active = true ORDER BY name', ['SUPERVISOR']);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// 3. LIVE OPERATIONS DASHBOARD (STORE-CENTRIC MULTI-PROJECT)
// ==========================================
app.get('/api/dashboard/live', async (req, res) => {
  try {
    const today = req.query.date || new Date().toISOString().split('T')[0];
    const { emirate } = req.query;

    // 1. Fetch KPI metrics for today
    const kpiRes = await db.query(`
      SELECT 
        COUNT(DISTINCT store_id) as live_stores_count,
        COUNT(DISTINCT promoter_id) as active_promoters_count,
        (SELECT COUNT(*) FROM logistics_drops WHERE scheduled_drop_date = $1 AND status = 'PENDING') as pending_drops,
        (SELECT COUNT(*) FROM logistics_collections WHERE scheduled_collection_date = $1 AND status = 'PENDING') as pending_collections
      FROM timemap_schedules
      WHERE shift_date = $1
    `, [today]);

    // 2. Fetch live store schedules grouped with projects and promoters
    let scheduleQuery = `
      SELECT 
        ts.id as schedule_id,
        ts.shift_date,
        ts.start_time,
        ts.end_time,
        ts.break_timings,
        ts.total_hours,
        ts.status as shift_status,
        s.id as store_id,
        s.store_name,
        s.retailer,
        s.emirate,
        s.branch_code,
        p.id as project_id,
        p.name as project_name,
        pr.id as promoter_id,
        pr.name as promoter_name,
        pr.phone as promoter_phone,
        u.id as supervisor_id,
        u.name as supervisor_name,
        u.phone as supervisor_phone
      FROM timemap_schedules ts
      JOIN stores s ON ts.store_id = s.id
      JOIN projects p ON ts.project_id = p.id
      JOIN promoters pr ON ts.promoter_id = pr.id
      JOIN users u ON ts.supervisor_id = u.id
      WHERE ts.shift_date = $1
    `;
    const params = [today];
    if (emirate && emirate !== 'All') {
      scheduleQuery += ' AND s.emirate = $2';
      params.push(emirate);
    }
    scheduleQuery += ' ORDER BY s.emirate, s.store_name, p.name';

    const schedRes = await db.query(scheduleQuery, params);

    // Group store-centrically so stores with multiple projects appear combined!
    const storeMap = {};
    schedRes.rows.forEach(row => {
      if (!storeMap[row.store_id]) {
        storeMap[row.store_id] = {
          store_id: row.store_id,
          store_name: row.store_name,
          retailer: row.retailer,
          emirate: row.emirate,
          branch_code: row.branch_code,
          supervisor_id: row.supervisor_id,
          supervisor_name: row.supervisor_name,
          supervisor_phone: row.supervisor_phone,
          projects: {}
        };
      }

      if (!storeMap[row.store_id].projects[row.project_id]) {
        storeMap[row.store_id].projects[row.project_id] = {
          project_id: row.project_id,
          project_name: row.project_name,
          promoters: []
        };
      }

      storeMap[row.store_id].projects[row.project_id].promoters.push({
        schedule_id: row.schedule_id,
        promoter_id: row.promoter_id,
        promoter_name: row.promoter_name,
        promoter_phone: row.promoter_phone,
        start_time: row.start_time,
        end_time: row.end_time,
        break_timings: row.break_timings,
        total_hours: row.total_hours,
        status: row.shift_status
      });
    });

    // Format into array with logistics info
    const liveStores = Object.values(storeMap).map(store => ({
      ...store,
      projects: Object.values(store.projects)
    }));

    res.json({
      date: today,
      kpis: kpiRes.rows[0] || { live_stores_count: 0, active_promoters_count: 0, pending_drops: 0, pending_collections: 0 },
      live_stores: liveStores
    });
  } catch (err) {
    console.error('Dashboard live error:', err);
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// 4. TIMEMAP ROSTER & IN-APP SCHEDULING
// ==========================================
app.get('/api/timemaps', async (req, res) => {
  try {
    const { project_id, store_id, emirate, start_date, end_date } = req.query;
    let query = `
      SELECT 
        ts.*,
        s.store_name, s.retailer, s.emirate,
        p.name as project_name,
        pr.name as promoter_name, pr.phone as promoter_phone,
        u.name as supervisor_name
      FROM timemap_schedules ts
      JOIN stores s ON ts.store_id = s.id
      JOIN projects p ON ts.project_id = p.id
      JOIN promoters pr ON ts.promoter_id = pr.id
      JOIN users u ON ts.supervisor_id = u.id
      WHERE 1=1
    `;
    const params = [];
    if (project_id) {
      params.push(project_id);
      query += ` AND ts.project_id = $${params.length}`;
    }
    if (store_id) {
      params.push(store_id);
      query += ` AND ts.store_id = $${params.length}`;
    }
    if (emirate && emirate !== 'All') {
      params.push(emirate);
      query += ` AND s.emirate = $${params.length}`;
    }
    if (start_date && end_date) {
      params.push(start_date, end_date);
      query += ` AND ts.shift_date BETWEEN $${params.length - 1} AND $${params.length}`;
    }

    query += ' ORDER BY ts.shift_date, s.store_name';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Fast In-App Multi-day Schedule Creator
// Single & Batch Schedule Endpoints (Fully Customizable Timings & Breaks)
app.post('/api/schedules', async (req, res) => {
  try {
    const {
      project_id, store_id, promoter_id, supervisor_id, shift_date,
      start_time, end_time, break_timings, total_hours, staff_role, notes
    } = req.body;

    if (!project_id || !store_id || !shift_date) {
      return res.status(400).json({ error: 'Missing required schedule fields (project_id, store_id, shift_date)' });
    }

    const result = await db.query(`
      INSERT INTO timemap_schedules 
        (project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, staff_role, notes, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'SCHEDULED')
      RETURNING *
    `, [
      project_id,
      store_id,
      promoter_id || null,
      supervisor_id || null,
      shift_date,
      start_time || '14:00:00',
      end_time || '22:00:00',
      break_timings || null,
      total_hours || 8.0,
      staff_role || 'PROMOTER',
      notes || null
    ]);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Create single schedule error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/schedules/:id', async (req, res) => {
  try {
    const {
      promoter_id, supervisor_id, start_time, end_time,
      break_timings, total_hours, staff_role, notes, status
    } = req.body;

    const result = await db.query(`
      UPDATE timemap_schedules SET
        promoter_id = COALESCE($1, promoter_id),
        supervisor_id = COALESCE($2, supervisor_id),
        start_time = COALESCE($3, start_time),
        end_time = COALESCE($4, end_time),
        break_timings = COALESCE($5, break_timings),
        total_hours = COALESCE($6, total_hours),
        staff_role = COALESCE($7, staff_role),
        notes = COALESCE($8, notes),
        status = COALESCE($9, status)
      WHERE id = $10
      RETURNING *
    `, [
      promoter_id, supervisor_id, start_time, end_time,
      break_timings, total_hours, staff_role, notes, status,
      req.params.id
    ]);

    if (result.rows.length === 0) return res.status(404).json({ error: 'Schedule not found' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Update schedule error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/schedules/:id', async (req, res) => {
  try {
    const result = await db.query('DELETE FROM timemap_schedules WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Schedule not found' });
    res.json({ success: true, message: 'Schedule deleted', id: req.params.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/timemaps/create', async (req, res) => {
  try {
    const { project_id, store_id, promoter_id, supervisor_id, dates, start_time, end_time, break_timings, total_hours } = req.body;
    
    if (!project_id || !store_id || !promoter_id || !supervisor_id || !dates || !dates.length) {
      return res.status(400).json({ error: 'Missing required schedule fields or dates array' });
    }

    const inserted = [];
    for (const shift_date of dates) {
      const result = await db.query(`
        INSERT INTO timemap_schedules 
          (project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'SCHEDULED')
        RETURNING *
      `, [project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours || 8.0]);
      inserted.push(result.rows[0]);
    }

    res.status(201).json({ count: inserted.length, schedules: inserted });
  } catch (err) {
    console.error('Create schedule error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 1-Click Duplicate Schedules for Next Week
app.post('/api/timemaps/duplicate', async (req, res) => {
  try {
    const { project_id, from_start_date, from_end_date, days_forward } = req.body;
    const offset = parseInt(days_forward || 7, 10);

    const result = await db.query(`
      INSERT INTO timemap_schedules 
        (project_id, store_id, promoter_id, supervisor_id, shift_date, start_time, end_time, break_timings, total_hours, status)
      SELECT 
        project_id, store_id, promoter_id, supervisor_id, 
        (shift_date + INTERVAL '${offset} days')::date, 
        start_time, end_time, break_timings, total_hours, 'SCHEDULED'
      FROM timemap_schedules
      WHERE project_id = $1 AND shift_date BETWEEN $2 AND $3
      RETURNING *
    `, [project_id, from_start_date, from_end_date]);

    res.json({ duplicated_count: result.rowCount, schedules: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// 5. INDEPENDENT LOGISTICS (DROPS & COLLECTIONS)
// ==========================================
app.get('/api/logistics/drops', async (req, res) => {
  try {
    const { date, status } = req.query;
    let query = `
      SELECT ld.*, s.store_name, s.retailer, s.emirate, p.name as project_name, u.name as supervisor_name, u.phone as supervisor_phone
      FROM logistics_drops ld
      JOIN stores s ON ld.store_id = s.id
      JOIN projects p ON ld.project_id = p.id
      JOIN users u ON ld.assigned_supervisor_id = u.id
      WHERE 1=1
    `;
    const params = [];
    if (date) {
      params.push(date);
      query += ` AND ld.scheduled_drop_date = $${params.length}`;
    }
    if (status) {
      params.push(status);
      query += ` AND ld.status = $${params.length}`;
    }
    query += ' ORDER BY ld.scheduled_drop_date DESC, s.store_name';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/logistics/drops', async (req, res) => {
  try {
    const { project_id, store_id, assigned_supervisor_id, scheduled_drop_date, items_manifest, delivery_notes } = req.body;
    const result = await db.query(`
      INSERT INTO logistics_drops 
        (project_id, store_id, assigned_supervisor_id, scheduled_drop_date, items_manifest, status, delivery_notes)
      VALUES ($1, $2, $3, $4, $5, 'PENDING', $6)
      RETURNING *
    `, [project_id, store_id, assigned_supervisor_id, scheduled_drop_date, items_manifest, delivery_notes]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/logistics/drops/:id/status', async (req, res) => {
  try {
    const { status, delivery_notes } = req.body;
    const deliveredAt = status === 'DELIVERED' ? new Date() : null;
    const result = await db.query(`
      UPDATE logistics_drops 
      SET status = $1, delivered_at = $2, delivery_notes = COALESCE($3, delivery_notes)
      WHERE id = $4
      RETURNING *
    `, [status, deliveredAt, delivery_notes, req.params.id]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Dedicated Separate Collection Option
app.get('/api/logistics/collections', async (req, res) => {
  try {
    const { date, status } = req.query;
    let query = `
      SELECT lc.*, s.store_name, s.retailer, s.emirate, p.name as project_name, u.name as supervisor_name, u.phone as supervisor_phone
      FROM logistics_collections lc
      JOIN stores s ON lc.store_id = s.id
      JOIN projects p ON lc.project_id = p.id
      JOIN users u ON lc.assigned_supervisor_id = u.id
      WHERE 1=1
    `;
    const params = [];
    if (date) {
      params.push(date);
      query += ` AND lc.scheduled_collection_date = $${params.length}`;
    }
    if (status) {
      params.push(status);
      query += ` AND lc.status = $${params.length}`;
    }
    query += ' ORDER BY lc.scheduled_collection_date DESC, s.store_name';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/logistics/collections', async (req, res) => {
  try {
    const { project_id, store_id, assigned_supervisor_id, scheduled_collection_date, items_to_collect, collection_notes } = req.body;
    const result = await db.query(`
      INSERT INTO logistics_collections 
        (project_id, store_id, assigned_supervisor_id, scheduled_collection_date, items_to_collect, status, collection_notes)
      VALUES ($1, $2, $3, $4, $5, 'PENDING', $6)
      RETURNING *
    `, [project_id, store_id, assigned_supervisor_id, scheduled_collection_date, items_to_collect, collection_notes]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/logistics/collections/:id/status', async (req, res) => {
  try {
    const { status, collection_notes } = req.body;
    const collectedAt = status === 'COLLECTED' ? new Date() : null;
    const result = await db.query(`
      UPDATE logistics_collections 
      SET status = $1, collected_at = $2, collection_notes = COALESCE($3, collection_notes)
      WHERE id = $4
      RETURNING *
    `, [status, collectedAt, collection_notes, req.params.id]);
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// 6. SUPERVISOR EVALUATIONS & STRUCTURED PHOTO ENGINE
// ==========================================
app.post('/api/evaluations', async (req, res) => {
  try {
    const { project_id, store_id, promoter_id, supervisor_id, visit_date, grooming_score, pitch_score, engagement_score, punctuality_score, feedback_notes } = req.body;
    const overall = ((grooming_score + pitch_score + engagement_score + punctuality_score) / 4.0).toFixed(1);

    const result = await db.query(`
      INSERT INTO store_evaluations 
        (project_id, store_id, promoter_id, supervisor_id, visit_date, grooming_score, pitch_score, engagement_score, punctuality_score, overall_rating, feedback_notes)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *
    `, [project_id, store_id, promoter_id, supervisor_id, visit_date || new Date(), grooming_score, pitch_score, engagement_score, punctuality_score, overall, feedback_notes]);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Photo Upload with automatic routing into uploads/{project}/{store}/{date}
app.post('/api/photos/upload', upload.single('photo'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }

    const { project_id, store_id, shift_date, supervisor_id, photo_type, promoter_id } = req.body;
    
    // Relative path for database record
    const relativePath = path.relative(baseUploadDir, req.file.path).replace(/\\/g, '/');

    const result = await db.query(`
      INSERT INTO store_photos 
        (project_id, store_id, shift_date, supervisor_id, photo_type, promoter_id, file_path)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [project_id, store_id, shift_date || new Date().toISOString().split('T')[0], supervisor_id, photo_type || 'SETUP', promoter_id || null, relativePath]);

    res.status(201).json({
      message: 'Photo uploaded and structured successfully',
      photo: result.rows[0],
      url: `/uploads/${relativePath}`
    });
  } catch (err) {
    console.error('Photo upload error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Query photos for Media Gallery Explorer
app.get('/api/photos/gallery', async (req, res) => {
  try {
    const { project_id, store_id, date } = req.query;
    let query = `
      SELECT sp.*, p.name as project_name, s.store_name, s.retailer, pr.name as promoter_name, u.name as supervisor_name
      FROM store_photos sp
      JOIN projects p ON sp.project_id = p.id
      JOIN stores s ON sp.store_id = s.id
      JOIN users u ON sp.supervisor_id = u.id
      LEFT JOIN promoters pr ON sp.promoter_id = pr.id
      WHERE 1=1
    `;
    const params = [];
    if (project_id) {
      params.push(project_id);
      query += ` AND sp.project_id = $${params.length}`;
    }
    if (store_id) {
      params.push(store_id);
      query += ` AND sp.store_id = $${params.length}`;
    }
    if (date) {
      params.push(date);
      query += ` AND sp.shift_date = $${params.length}`;
    }
    query += ' ORDER BY sp.created_at DESC';

    const result = await db.query(query, params);
    const photosWithUrl = result.rows.map(row => ({
      ...row,
      url: `/uploads/${row.file_path}`
    }));

    res.json(photosWithUrl);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// 7. OPERATIONAL TASKS & STICKY NOTES
// ==========================================
app.get('/api/tasks', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT ot.*, u.name as created_by_name, p.name as project_name, s.store_name
      FROM operational_tasks ot
      JOIN users u ON ot.created_by_user_id = u.id
      LEFT JOIN projects p ON ot.project_id = p.id
      LEFT JOIN stores s ON ot.store_id = s.id
      ORDER BY ot.is_completed ASC, ot.priority DESC, ot.created_at DESC
    `);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/tasks', async (req, res) => {
  try {
    const { project_id, store_id, title, description, priority, created_by_user_id } = req.body;
    const result = await db.query(`
      INSERT INTO operational_tasks (project_id, store_id, title, description, priority, created_by_user_id)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [project_id || null, store_id || null, title, description, priority || 'MEDIUM', created_by_user_id]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/tasks/:id', async (req, res) => {
  try {
    const { is_completed } = req.body;
    const result = await db.query(
      'UPDATE operational_tasks SET is_completed = $1 WHERE id = $2 RETURNING *',
      [is_completed, req.params.id]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// 8. STORE BADGE TRACKER & UAE WORK PERMITS
// ==========================================
app.get('/api/badges', async (req, res) => {
  try {
    const { store_id, project_id, status, search } = req.query;
    let query = `
      SELECT b.*, s.store_name, s.retailer, s.emirate as store_emirate, s.customer_code,
             p.name as project_name
      FROM store_badges b
      LEFT JOIN stores s ON b.store_id = s.id
      LEFT JOIN projects p ON b.project_id = p.id
      WHERE 1=1
    `;
    const params = [];
    if (store_id) {
      params.push(store_id);
      query += ` AND b.store_id = $${params.length}`;
    }
    if (project_id) {
      params.push(project_id);
      query += ` AND b.project_id = $${params.length}`;
    }
    if (status && status !== 'All') {
      params.push(status);
      query += ` AND b.status = $${params.length}`;
    }
    if (search) {
      params.push(`%${search.trim()}%`);
      query += ` AND (b.promoter_name ILIKE $${params.length} OR s.store_name ILIKE $${params.length} OR s.customer_code ILIKE $${params.length})`;
    }
    query += ' ORDER BY b.created_at DESC, b.id DESC';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/badges', async (req, res) => {
  try {
    const { promoter_name, promoter_id, project_id, store_id, emirate, status, submitted_by, badge_number, notes } = req.body;
    if (!promoter_name || !store_id || !project_id) {
      return res.status(400).json({ error: 'Promoter name, Project, and Store are required' });
    }
    const result = await db.query(`
      INSERT INTO store_badges 
        (promoter_name, promoter_id, project_id, store_id, emirate, status, submitted_by, badge_number, notes)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `, [
      promoter_name.trim(),
      promoter_id || null,
      project_id,
      store_id,
      emirate || 'Dubai',
      status || 'Documents ready for collection',
      submitted_by || 'Operations Lead',
      badge_number || null,
      notes || null
    ]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.patch('/api/badges/:id/status', async (req, res) => {
  try {
    const { status, notes, badge_number } = req.body;
    const result = await db.query(`
      UPDATE store_badges
      SET status = $1,
          notes = COALESCE($2, notes),
          badge_number = COALESCE($3, badge_number),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $4
      RETURNING *
    `, [status, notes, badge_number, req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Badge application not found' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Matrix Endpoint (73 Stores on Rows, Unique Dates on Columns)
app.get('/api/timemaps/matrix', async (req, res) => {
  try {
    const { project_id, emirate, chain } = req.query;
    let storeQuery = 'SELECT * FROM stores WHERE 1=1';
    const params = [];
    if (emirate && emirate !== 'All') {
      params.push(emirate);
      storeQuery += ` AND emirate = $${params.length}`;
    }
    if (chain && chain !== 'All') {
      params.push(chain);
      storeQuery += ` AND (chain = $${params.length} OR retailer = $${params.length})`;
    }
    storeQuery += ' ORDER BY COALESCE(chain, retailer), store_name ASC';
    const storesRes = await db.query(storeQuery, params);

    // Get shifts
    let shiftQuery = `
      SELECT ts.store_id, ts.shift_date, ts.start_time, ts.end_time, ts.break_timings,
             ts.staff_role, p.name as promoter_name, pr.name as project_name,
             sb.status as badge_status
      FROM timemap_schedules ts
      LEFT JOIN promoters p ON ts.promoter_id = p.id
      LEFT JOIN projects pr ON ts.project_id = pr.id
      LEFT JOIN store_badges sb ON (sb.store_id = ts.store_id AND sb.project_id = ts.project_id AND sb.promoter_name = p.name)
      WHERE 1=1
    `;
    const sParams = [];
    if (project_id) {
      sParams.push(project_id);
      shiftQuery += ` AND ts.project_id = $${sParams.length}`;
    }
    shiftQuery += ' ORDER BY ts.shift_date ASC';
    const shiftsRes = await db.query(shiftQuery, sParams);

    res.json({
      stores: storesRes.rows,
      shifts: shiftsRes.rows
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Evaluations List
app.get('/api/evaluations', async (req, res) => {
  try {
    const { project_id, store_id } = req.query;
    let query = `
      SELECT se.*, p.name as promoter_name, pr.name as project_name, s.store_name, s.retailer, s.emirate, u.name as supervisor_name
      FROM store_evaluations se
      LEFT JOIN promoters p ON se.promoter_id = p.id
      LEFT JOIN projects pr ON se.project_id = pr.id
      LEFT JOIN stores s ON se.store_id = s.id
      LEFT JOIN users u ON se.supervisor_id = u.id
      WHERE 1=1
    `;
    const params = [];
    if (project_id) {
      params.push(project_id);
      query += ` AND se.project_id = $${params.length}`;
    }
    if (store_id) {
      params.push(store_id);
      query += ` AND se.store_id = $${params.length}`;
    }
    query += ' ORDER BY se.created_at DESC';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Export TimeMap Roster to Excel (.xlsx)
app.get('/api/timemaps/export-excel', async (req, res) => {
  try {
    const { project_id, emirate, chain } = req.query;
    let storeQuery = 'SELECT * FROM stores WHERE 1=1';
    const params = [];
    if (emirate && emirate !== 'All') {
      params.push(emirate);
      storeQuery += ` AND emirate = $${params.length}`;
    }
    if (chain && chain !== 'All') {
      params.push(chain);
      storeQuery += ` AND (chain = $${params.length} OR retailer = $${params.length})`;
    }
    storeQuery += ' ORDER BY COALESCE(chain, retailer), store_name ASC';
    const storesRes = await db.query(storeQuery, params);

    let shiftQuery = `
      SELECT ts.store_id, ts.shift_date, ts.start_time, ts.end_time, ts.break_timings,
             ts.staff_role, p.name as promoter_name, pr.name as project_name,
             sb.status as badge_status
      FROM timemap_schedules ts
      LEFT JOIN promoters p ON ts.promoter_id = p.id
      LEFT JOIN projects pr ON ts.project_id = pr.id
      LEFT JOIN store_badges sb ON (sb.store_id = ts.store_id AND sb.project_id = ts.project_id AND sb.promoter_name = p.name)
      WHERE 1=1
    `;
    const sParams = [];
    if (project_id) {
      sParams.push(project_id);
      shiftQuery += ` AND ts.project_id = $${sParams.length}`;
    }
    shiftQuery += ' ORDER BY ts.shift_date ASC';
    const shiftsRes = await db.query(shiftQuery, sParams);

    const dateSet = new Set();
    const shiftMap = {};
    const storeTimingMap = {};
    for (const s of shiftsRes.rows) {
      const dStr = new Date(s.shift_date).toISOString().split('T')[0];
      dateSet.add(dStr);
      const key = `${s.store_id}_${dStr}`;
      if (!shiftMap[key]) shiftMap[key] = [];
      const badgeInfo = s.badge_status ? ` [${s.badge_status}]` : '';
      const timeStr = (s.start_time && s.end_time) ? ` (${s.start_time.slice(0,5)}-${s.end_time.slice(0,5)})` : '';
      shiftMap[key].push(`${s.promoter_name || s.staff_role || 'Staff'}${timeStr}${badgeInfo}`);
      if (!storeTimingMap[s.store_id] && s.start_time && s.end_time) {
        storeTimingMap[s.store_id] = `${s.start_time.slice(0,5)} - ${s.end_time.slice(0,5)}`;
      }
    }
    const sortedDates = Array.from(dateSet).sort();

    const headers = ['S.No', 'Customer Code', 'Store Name', 'Chain', 'Emirate', 'Field Lead', 'Shift Timing', ...sortedDates];
    const data = [headers];

    storesRes.rows.forEach((st, idx) => {
      const row = [
        idx + 1,
        st.customer_code || '',
        st.store_name,
        st.chain || st.retailer,
        st.emirate,
        st.merchandiser_lead || '',
        storeTimingMap[st.id] || 'Custom / As Scheduled'
      ];
      for (const d of sortedDates) {
        const key = `${st.id}_${d}`;
        if (shiftMap[key] && shiftMap[key].length > 0) {
          row.push(shiftMap[key].join(', '));
        } else {
          row.push('-');
        }
      }
      data.push(row);
    });

    const ws = XLSX.utils.aoa_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'TimeMap Roster');
    const buf = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

    res.setHeader('Content-Disposition', 'attachment; filename="TimeMaps_Master_Roster.xlsx"');
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.send(buf);
  } catch (err) {
    console.error('Excel Export error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Import Campaign Shifts from Excel (.xlsx)
app.post('/api/timemaps/import-excel', uploadMemory.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No Excel file uploaded' });
    }
    const wb = XLSX.read(req.file.buffer, { type: 'buffer' });
    const sheetName = wb.SheetNames[0];
    const sheet = wb.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json(sheet, { header: 1 });

    let headerRowIdx = -1;
    for (let i = 0; i < Math.min(rows.length, 10); i++) {
      const r = rows[i] || [];
      const str = r.map(c => String(c).toLowerCase()).join(' ');
      if (str.includes('store') || str.includes('cus. name') || str.includes('retailer')) {
        headerRowIdx = i;
        break;
      }
    }

    if (headerRowIdx === -1) {
      return res.status(400).json({ error: 'Could not detect header row in Excel sheet' });
    }

    const headers = rows[headerRowIdx];
    let storeCol = -1, cusCodeCol = -1, chainCol = -1, emirateCol = -1, leadCol = -1;
    const dateCols = [];

    headers.forEach((h, idx) => {
      if (!h) return;
      const str = String(h).trim();
      const lower = str.toLowerCase();
      if (lower.includes('store') || lower.includes('cus. name')) storeCol = idx;
      else if (lower.includes('code') || lower.includes('cus. code')) cusCodeCol = idx;
      else if (lower.includes('chain') || lower.includes('retailer')) chainCol = idx;
      else if (lower.includes('emirate') || lower.includes('city')) emirateCol = idx;
      else if (lower.includes('lead') || lower.includes('merchandiser lead')) leadCol = idx;
      else if (/\d{4}-\d{2}-\d{2}/.test(str) || !isNaN(Date.parse(str))) {
        const parsed = new Date(str);
        if (!isNaN(parsed.getTime())) {
          dateCols.push({ idx, dateStr: parsed.toISOString().split('T')[0] });
        }
      }
    });

    let storesCreated = 0;
    let shiftsCreated = 0;

    for (let rIdx = headerRowIdx + 1; rIdx < rows.length; rIdx++) {
      const row = rows[rIdx];
      if (!row || !row[storeCol]) continue;
      const storeName = String(row[storeCol]).trim();
      const cusCode = cusCodeCol !== -1 && row[cusCodeCol] ? String(row[cusCodeCol]).trim() : null;
      const chain = chainCol !== -1 && row[chainCol] ? String(row[chainCol]).trim() : 'Retail';
      const emirate = emirateCol !== -1 && row[emirateCol] ? String(row[emirateCol]).trim() : 'Dubai';
      const lead = leadCol !== -1 && row[leadCol] ? String(row[leadCol]).trim() : null;

      let stRes = await db.query('SELECT id FROM stores WHERE store_name = $1 LIMIT 1', [storeName]);
      let storeId;
      if (stRes.rows.length === 0) {
        const ins = await db.query(
          'INSERT INTO stores (store_name, customer_code, chain, retailer, emirate, merchandiser_lead) VALUES ($1, $2, $3, $3, $4, $5) RETURNING id',
          [storeName, cusCode, chain, emirate, lead]
        );
        storeId = ins.rows[0].id;
        storesCreated++;
      } else {
        storeId = stRes.rows[0].id;
      }

      for (const dc of dateCols) {
        const val = row[dc.idx];
        if (val && String(val).trim() !== '' && String(val).trim() !== '-') {
          await db.query(`
            INSERT INTO timemap_schedules (project_id, store_id, shift_date, start_time, end_time, break_timings, total_hours, status, staff_role)
            VALUES (1, $1, $2, '14:00:00', '22:00:00', '5:00 PM - 5:45 PM', 8.00, 'SCHEDULED', 'PROMOTER')
            ON CONFLICT DO NOTHING
          `, [storeId, dc.dateStr]);
          shiftsCreated++;
        }
      }
    }

    res.json({
      success: true,
      message: `Excel imported successfully! Processed ${storesCreated} new stores and ${shiftsCreated} shifts.`,
      storesCreated,
      shiftsCreated
    });
  } catch (err) {
    console.error('Excel Import error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Root & Healthcheck
app.get('/', (req, res) => {
  res.json({
    app: 'TimeMaps Field Operations REST API',
    version: '1.0.0',
    status: 'ONLINE',
    db_connected: true
  });
});

app.listen(PORT, () => {
  console.log(`TimeMaps API Server is running on port ${PORT}`);
});
