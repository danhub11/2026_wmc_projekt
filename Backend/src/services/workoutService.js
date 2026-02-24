const express = require('express');
const router = express.Router();
const db = require('../models/database');

router.post('/workouts', (req, res) => {
    const { exercise_id, weight_kg, reps, set_type, notes } = req.body;
    
    if (!exercise_id || !reps) return res.status(400).json({ error: "Fehlende Trainingsdaten" });

    const date = new Date().toISOString();
    const safeType = set_type || 'normal'; 
    const safeNotes = notes || "";

    const sql = `INSERT INTO workouts (exercise_id, weight_kg, reps, set_type, date, notes) VALUES (?, ?, ?, ?, ?, ?)`;
    
    db.run(sql, [exercise_id, weight_kg, reps, safeType, date, safeNotes], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID, status: "Saved", date: date });
    });
});

router.delete('/workouts/:id', (req, res) => {
    db.run(`DELETE FROM workouts WHERE id = ?`, req.params.id, function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ deleted: this.changes });
    });
});

module.exports = router;