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

router.get('/dashboard/highlights', (req, res) => {
    const now = new Date();
    const monday = new Date(now);
    monday.setHours(0, 0, 0, 0);
    monday.setDate(now.getDate() - ((now.getDay() + 6) % 7));
    const nextMonday = new Date(monday);
    nextMonday.setDate(monday.getDate() + 7);

    const weekStart = monday.toISOString();
    const weekEnd = nextMonday.toISOString();

    const queries = {
        strongestLift: `
            SELECT e.name as exercise_name, w.weight_kg, w.reps
            FROM workouts w
            JOIN exercises e ON e.id = w.exercise_id
            WHERE w.date >= ? AND w.date < ? AND w.set_type != 'warmup'
            ORDER BY w.weight_kg DESC, w.reps DESC
            LIMIT 1
        `,
        mostSets: `
            SELECT e.name as exercise_name, COUNT(w.id) as set_count
            FROM workouts w
            JOIN exercises e ON e.id = w.exercise_id
            WHERE w.date >= ? AND w.date < ? AND w.set_type != 'warmup'
            GROUP BY w.exercise_id
            ORDER BY set_count DESC, e.name ASC
            LIMIT 1
        `,
        highestVolume: `
            SELECT e.name as exercise_name, SUM(COALESCE(w.weight_kg, 0) * COALESCE(w.reps, 0)) as volume_kg
            FROM workouts w
            JOIN exercises e ON e.id = w.exercise_id
            WHERE w.date >= ? AND w.date < ? AND w.set_type != 'warmup'
            GROUP BY w.exercise_id
            ORDER BY volume_kg DESC, e.name ASC
            LIMIT 1
        `,
        newPr: `
            WITH this_week AS (
                SELECT w.exercise_id, MAX(w.weight_kg) as week_max
                FROM workouts w
                WHERE w.date >= ? AND w.date < ? AND w.set_type != 'warmup'
                GROUP BY w.exercise_id
            ),
            previous_best AS (
                SELECT w.exercise_id, MAX(w.weight_kg) as previous_max
                FROM workouts w
                WHERE w.date < ? AND w.set_type != 'warmup'
                GROUP BY w.exercise_id
            )
            SELECT e.name as exercise_name,
                   tw.week_max as weight_kg,
                   COALESCE(pb.previous_max, 0) as previous_max,
                   (tw.week_max - COALESCE(pb.previous_max, 0)) as improvement
            FROM this_week tw
            JOIN exercises e ON e.id = tw.exercise_id
            LEFT JOIN previous_best pb ON pb.exercise_id = tw.exercise_id
            WHERE tw.week_max > COALESCE(pb.previous_max, 0)
            ORDER BY improvement DESC, tw.week_max DESC
            LIMIT 1
        `,
        newPrCount: `
            WITH this_week AS (
                SELECT w.exercise_id, MAX(w.weight_kg) as week_max
                FROM workouts w
                WHERE w.date >= ? AND w.date < ? AND w.set_type != 'warmup'
                GROUP BY w.exercise_id
            ),
            previous_best AS (
                SELECT w.exercise_id, MAX(w.weight_kg) as previous_max
                FROM workouts w
                WHERE w.date < ? AND w.set_type != 'warmup'
                GROUP BY w.exercise_id
            )
            SELECT COUNT(*) as pr_count
            FROM this_week tw
            LEFT JOIN previous_best pb ON pb.exercise_id = tw.exercise_id
            WHERE tw.week_max > COALESCE(pb.previous_max, 0)
        `,
    };

    db.get(queries.strongestLift, [weekStart, weekEnd], (errStrong, strongestLift) => {
        if (errStrong) return res.status(500).json({ error: errStrong.message });

        db.get(queries.mostSets, [weekStart, weekEnd], (errSets, mostSets) => {
            if (errSets) return res.status(500).json({ error: errSets.message });

            db.get(queries.highestVolume, [weekStart, weekEnd], (errVolume, highestVolume) => {
                if (errVolume) return res.status(500).json({ error: errVolume.message });

                db.get(queries.newPr, [weekStart, weekEnd, weekStart], (errPr, newPr) => {
                    if (errPr) return res.status(500).json({ error: errPr.message });

                    db.get(queries.newPrCount, [weekStart, weekEnd, weekStart], (errPrCount, prCountRow) => {
                        if (errPrCount) return res.status(500).json({ error: errPrCount.message });

                        res.json({
                            strongestLift: strongestLift || null,
                            newPr: newPr || null,
                            newPrCount: prCountRow?.pr_count || 0,
                            mostSets: mostSets || null,
                            highestVolume: highestVolume || null,
                        });
                    });
                });
            });
        });
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