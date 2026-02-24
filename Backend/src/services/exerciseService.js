const express = require('express');
const router = express.Router();
const db = require('../models/database');

router.get('/exercises', (req, res) => {
    db.all("SELECT * FROM exercises ORDER BY name", [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

router.post('/exercises', (req, res) => {
    const { name, muscle_group } = req.body;
    if (!name || !muscle_group) return res.status(400).json({ error: "Fehlende Daten" });
    
    db.run(`INSERT INTO exercises (name, muscle_group, default_rest_seconds) VALUES (?, ?, 90)`, 
        [name, muscle_group], 
        function(err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: this.lastID, name: name, muscle_group: muscle_group });
        }
    );
});

module.exports = router;