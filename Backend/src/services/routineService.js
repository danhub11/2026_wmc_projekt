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

router.put('/routines/:id', (req, res) => {
    const { name } = req.body;
    if (!name || !name.trim()) {
        return res.status(400).json({ error: 'Name fehlt' });
    }

    db.run(
        `UPDATE routines SET name = ? WHERE id = ?`,
        [name.trim(), req.params.id],
        function(err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ status: 'ok', updated: this.changes });
        }
    );
});

router.put('/routines/:id/exercises', (req, res) => {
    const routineId = req.params.id;
    const exerciseIds = Array.isArray(req.body.exercise_ids)
        ? req.body.exercise_ids
        : [];

    db.run(
        `DELETE FROM routine_exercises WHERE routine_id = ?`,
        [routineId],
        function(deleteErr) {
            if (deleteErr) return res.status(500).json({ error: deleteErr.message });

            if (exerciseIds.length === 0) {
                return res.json({ status: 'ok', count: 0 });
            }

            const stmt = db.prepare(
                `INSERT INTO routine_exercises (routine_id, exercise_id) VALUES (?, ?)`
            );

            for (const exerciseId of exerciseIds) {
                stmt.run([routineId, exerciseId]);
            }

            stmt.finalize((insertErr) => {
                if (insertErr) return res.status(500).json({ error: insertErr.message });
                res.json({ status: 'ok', count: exerciseIds.length });
            });
        }
    );
});

router.delete('/routines/:id', (req, res) => {
    const routineId = req.params.id;
    db.run(
        `DELETE FROM routine_exercises WHERE routine_id = ?`,
        [routineId],
        function(exErr) {
            if (exErr) return res.status(500).json({ error: exErr.message });

            db.run(`DELETE FROM routines WHERE id = ?`, [routineId], function(rErr) {
                if (rErr) return res.status(500).json({ error: rErr.message });
                res.json({ status: 'ok', deleted: this.changes });
            });
        }
    );
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