const express = require('express');
const router = express.Router();
const db = require('../models/database');

router.post('/measurements', (req, res) => {
    const { type, value } = req.body;
    const date = new Date().toISOString();
    db.run(`INSERT INTO measurements (type, value, date) VALUES (?, ?, ?)`, 
        [type, value, date], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID });
    });
});

router.get('/measurements/:type', (req, res) => {
    db.all(`SELECT * FROM measurements WHERE type = ? ORDER BY date ASC`, 
        [req.params.type], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

module.exports = router;