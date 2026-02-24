const express = require('express');
const router = express.Router();
const db = require('../models/database');

router.get('/history/:exerciseId', (req, res) => {
    const sql = `SELECT * FROM workouts WHERE exercise_id = ? AND set_type != 'warmup' ORDER BY date ASC`;
    db.all(sql, [req.params.exerciseId], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

router.get('/dashboard/weekly', (req, res) => {
    const sql = `
        SELECT substr(date, 1, 10) as day, COUNT(*) as sets 
        FROM workouts 
        GROUP BY day 
        ORDER BY day DESC 
        LIMIT 7`;
    db.all(sql, [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

router.get('/stats/pr/:exerciseId', (req, res) => {
    const sql = `
        SELECT MAX(weight_kg) as max_weight, date, reps 
        FROM workouts 
        WHERE exercise_id = ? AND set_type != 'warmup'
    `;
    db.get(sql, [req.params.exerciseId], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(row);
    });
});

router.get('/stats/distribution', (req, res) => {
    const sql = `
        SELECT e.muscle_group, COUNT(w.id) as set_count
        FROM workouts w
        JOIN exercises e ON w.exercise_id = e.id
        GROUP BY e.muscle_group
        ORDER BY set_count DESC
    `;
    db.all(sql, [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

router.get('/stats/ranking/:exerciseId', (req, res) => {
    const sql = `
        SELECT e.name, MAX(w.weight_kg) as max_weight 
        FROM exercises e 
        LEFT JOIN workouts w ON e.id = w.exercise_id 
        WHERE e.id = ? AND w.set_type != 'warmup'
    `;
    
    db.get(sql, [req.params.exerciseId], (err, userRecord) => {
        if (err) return res.status(500).json({ error: err.message });
        
        if (!userRecord || !userRecord.max_weight) {
            return res.json({ rank: "Unrated", percentile: "-", icon: "grey_circle" });
        }

        db.get("SELECT * FROM strength_standards WHERE exercise_name = ?", [userRecord.name], (err, std) => {
            if (err) return res.status(500).json({ error: err.message });
            
            if (!std) {
                return res.json({ rank: "Custom", percentile: "N/A", icon: "blue_circle" });
            }

            const w = userRecord.max_weight;
            let result = { rank: "Beginner", percentile: "Top 95%", icon: "bronze_medal" };

            if (w >= std.elite) {
                result = { rank: "Elite", percentile: "Top 0.1%", icon: "diamond" };
            } else if (w >= std.advanced) {
                result = { rank: "Advanced", percentile: "Top 5%", icon: "trophy" };
            } else if (w >= std.intermediate) {
                result = { rank: "Intermediate", percentile: "Top 20%", icon: "gold_medal" };
            } else if (w >= std.novice) {
                result = { rank: "Novice", percentile: "Top 50%", icon: "silver_medal" };
            }

            res.json(result);
        });
    });
});

module.exports = router;