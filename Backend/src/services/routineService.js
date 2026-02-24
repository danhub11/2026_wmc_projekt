const express = require('express');
const router = express.Router();
const db = require('../models/database');

router.post('/routines', (req, res) => {
    const { name } = req.body;
    db.run(`INSERT INTO routines (name) VALUES (?)`, [name], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID, name: name });
    });
});

router.get('/routines', (req, res) => {
    db.all("SELECT * FROM routines", [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

router.post('/routines/add-exercise', (req, res) => {
    const { routine_id, exercise_id } = req.body;
    db.run(`INSERT INTO routine_exercises (routine_id, exercise_id) VALUES (?, ?)`, 
        [routine_id, exercise_id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ status: "ok" });
    });
});

router.get('/routines/:id', (req, res) => {
    const sql = `
        SELECT e.* FROM exercises e
        JOIN routine_exercises re ON e.id = re.exercise_id
        WHERE re.routine_id = ?
    `;
    db.all(sql, [req.params.id], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

module.exports = router;