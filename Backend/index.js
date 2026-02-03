const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');

const app = express();
const port = 3000;

// Middleware
app.use(express.json());
app.use(cors());

// Datenbank Verbindung
const db = new sqlite3.Database('./ironlog.db', (err) => {
    if (err) {
        console.error(err.message);
    } else {
        console.log('Verbunden mit der IronLog Datenbank (FULL MASTER EDITION).');
    }
});

// --- DATENBANK STRUKTUR & INITIALISIERUNG ---
db.serialize(() => {
    // 1. Tabelle: Übungen (Stammdaten mit Timer)
    db.run(`CREATE TABLE IF NOT EXISTS exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        default_rest_seconds INTEGER DEFAULT 90
    )`);

    // 2. Tabelle: Workouts (Das Tagebuch)
    db.run(`CREATE TABLE IF NOT EXISTS workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER,
        weight_kg REAL,
        reps INTEGER,
        set_type TEXT DEFAULT 'normal',
        date TEXT,
        notes TEXT,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id)
    )`);

    // 3. Tabelle: Routinen (Trainingspläne Namen)
    db.run(`CREATE TABLE IF NOT EXISTS routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
    )`);

    // 4. Tabelle: Routine-Inhalt (Verknüpfung)
    db.run(`CREATE TABLE IF NOT EXISTS routine_exercises (
        routine_id INTEGER,
        exercise_id INTEGER,
        FOREIGN KEY (routine_id) REFERENCES routines (id),
        FOREIGN KEY (exercise_id) REFERENCES exercises (id)
    )`);

    // 5. Tabelle: Körperdaten (Tracking)
    db.run(`CREATE TABLE IF NOT EXISTS measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL, 
        value REAL NOT NULL,
        date TEXT
    )`);

    // 6. Tabelle: Kraftstandards (Für das Ranking System)
    db.run(`CREATE TABLE IF NOT EXISTS strength_standards (
        exercise_name TEXT PRIMARY KEY,
        beginner REAL,
        novice REAL,
        intermediate REAL,
        advanced REAL,
        elite REAL
    )`);

    // --- SEEDING (Datenbank befüllen) ---
    db.get("SELECT count(*) as count FROM exercises", (err, row) => {
        if (row && row.count === 0) {
            console.log("Datenbank ist leer. Starte vollständiges Seeding...");
            
            const insertEx = 'INSERT INTO exercises (name, muscle_group, default_rest_seconds) VALUES (?,?,?)';
            const insertStd = 'INSERT INTO strength_standards (exercise_name, beginner, novice, intermediate, advanced, elite) VALUES (?,?,?,?,?,?)';
            
            db.serialize(() => {
                db.run("BEGIN TRANSACTION");

                // --- 1. DER KOMPLETTE ÜBUNGSKATALOG ---
                
                // BRUST (Chest)
                db.run(insertEx, ['Bench Press (Barbell)', 'Chest', 180]);
                db.run(insertEx, ['Bench Press (Dumbbell)', 'Chest', 120]);
                db.run(insertEx, ['Incline Bench Press (Barbell)', 'Chest', 180]);
                db.run(insertEx, ['Incline Bench Press (Dumbbell)', 'Chest', 120]);
                db.run(insertEx, ['Decline Bench Press', 'Chest', 120]);
                db.run(insertEx, ['Chest Press Machine', 'Chest', 90]);
                db.run(insertEx, ['Push-ups', 'Chest', 60]);
                db.run(insertEx, ['Weighted Push-ups', 'Chest', 90]);
                db.run(insertEx, ['Dips (Chest Focus)', 'Chest', 120]);
                db.run(insertEx, ['Cable Flyes (High-to-Low)', 'Chest', 60]);
                db.run(insertEx, ['Cable Flyes (Low-to-High)', 'Chest', 60]);
                db.run(insertEx, ['Pec Deck / Butterfly', 'Chest', 60]);

                // RÜCKEN (Back)
                db.run(insertEx, ['Deadlift (Conventional)', 'Back', 180]);
                db.run(insertEx, ['Deadlift (Sumo)', 'Back', 180]);
                db.run(insertEx, ['Pull-ups', 'Back', 120]);
                db.run(insertEx, ['Chin-ups', 'Back', 120]);
                db.run(insertEx, ['Lat Pulldown (Wide Grip)', 'Back', 90]);
                db.run(insertEx, ['Lat Pulldown (Close Grip)', 'Back', 90]);
                db.run(insertEx, ['Barbell Row', 'Back', 120]);
                db.run(insertEx, ['Pendlay Row', 'Back', 120]);
                db.run(insertEx, ['Dumbbell Row', 'Back', 90]);
                db.run(insertEx, ['Seated Cable Row', 'Back', 90]);
                db.run(insertEx, ['T-Bar Row', 'Back', 120]);
                db.run(insertEx, ['Face Pulls', 'Back', 60]);
                db.run(insertEx, ['Shrugs (Barbell)', 'Back', 90]);
                db.run(insertEx, ['Shrugs (Dumbbell)', 'Back', 90]);
                db.run(insertEx, ['Hyperextensions', 'Back', 60]);

                // BEINE (Legs)
                db.run(insertEx, ['Squat (Barbell High Bar)', 'Legs', 180]);
                db.run(insertEx, ['Squat (Barbell Low Bar)', 'Legs', 180]);
                db.run(insertEx, ['Front Squat', 'Legs', 150]);
                db.run(insertEx, ['Goblet Squat', 'Legs', 90]);
                db.run(insertEx, ['Leg Press', 'Legs', 120]);
                db.run(insertEx, ['Lunges (Walking)', 'Legs', 90]);
                db.run(insertEx, ['Bulgarian Split Squat', 'Legs', 120]);
                db.run(insertEx, ['Romanian Deadlift', 'Legs', 150]);
                db.run(insertEx, ['Leg Extension', 'Legs', 60]);
                db.run(insertEx, ['Leg Curl (Seated)', 'Legs', 60]);
                db.run(insertEx, ['Leg Curl (Lying)', 'Legs', 60]);
                db.run(insertEx, ['Calf Raises (Standing)', 'Legs', 60]);
                db.run(insertEx, ['Calf Raises (Seated)', 'Legs', 60]);

                // SCHULTERN (Shoulders)
                db.run(insertEx, ['Overhead Press (Military Press)', 'Shoulders', 180]);
                db.run(insertEx, ['Seated Dumbbell Press', 'Shoulders', 120]);
                db.run(insertEx, ['Arnold Press', 'Shoulders', 90]);
                db.run(insertEx, ['Lateral Raises (Dumbbell)', 'Shoulders', 60]);
                db.run(insertEx, ['Lateral Raises (Cable)', 'Shoulders', 60]);
                db.run(insertEx, ['Front Raises', 'Shoulders', 60]);
                db.run(insertEx, ['Reverse Flyes', 'Shoulders', 60]);
                db.run(insertEx, ['Upright Row', 'Shoulders', 90]);

                // ARME (Arms)
                db.run(insertEx, ['Barbell Curl', 'Arms', 90]);
                db.run(insertEx, ['Dumbbell Curl', 'Arms', 90]);
                db.run(insertEx, ['Hammer Curl', 'Arms', 90]);
                db.run(insertEx, ['Preacher Curl', 'Arms', 60]);
                db.run(insertEx, ['Concentration Curl', 'Arms', 60]);
                db.run(insertEx, ['Tricep Pushdown (Rope)', 'Arms', 60]);
                db.run(insertEx, ['Tricep Pushdown (Bar)', 'Arms', 60]);
                db.run(insertEx, ['Skullcrushers', 'Arms', 90]);
                db.run(insertEx, ['Overhead Tricep Extension', 'Arms', 90]);
                db.run(insertEx, ['Close-Grip Bench Press', 'Arms', 120]);
                db.run(insertEx, ['Tricep Dips', 'Arms', 90]);

                // CORE (Abs)
                db.run(insertEx, ['Plank', 'Core', 60]);
                db.run(insertEx, ['Crunches', 'Core', 60]);
                db.run(insertEx, ['Leg Raises (Hanging)', 'Core', 90]);
                db.run(insertEx, ['Russian Twist', 'Core', 60]);
                db.run(insertEx, ['Ab Wheel Rollout', 'Core', 90]);
                db.run(insertEx, ['Cable Crunch', 'Core', 60]);

                // CARDIO & FUNCTIONAL
                db.run(insertEx, ['Running (Treadmill)', 'Cardio', 0]);
                db.run(insertEx, ['Cycling', 'Cardio', 0]);
                db.run(insertEx, ['Rowing Machine', 'Cardio', 0]);
                db.run(insertEx, ['Elliptical', 'Cardio', 0]);
                db.run(insertEx, ['Farmer’s Walk', 'Full Body', 90]);

                // --- 2. DIE KRAFTSTANDARDS (Referenzwerte für das Ranking) ---
                // Werte basieren auf 1RM (One Rep Max) für einen 80kg Mann
                // Name muss exakt mit dem oben übereinstimmen!
                
                db.run(insertStd, ['Bench Press (Barbell)', 40, 60, 85, 110, 140]);
                db.run(insertStd, ['Squat (Barbell High Bar)', 60, 85, 110, 150, 190]);
                db.run(insertStd, ['Deadlift (Conventional)', 70, 100, 140, 190, 240]);
                db.run(insertStd, ['Overhead Press (Military Press)', 25, 40, 55, 75, 95]);
                db.run(insertStd, ['Pull-ups', 1, 5, 12, 20, 30]); // Hier in Reps gedacht (oder Zusatzgewicht)

                db.run("COMMIT");
            });
            console.log("-> 75+ Übungen und Standards erfolgreich geladen!");
        }
    });
});

// --- API ROUTEN ---

// === 1. BASIS: Übungen verwalten ===

// Alle Übungen laden (Alphabetisch)
app.get('/api/exercises', (req, res) => {
    db.all("SELECT * FROM exercises ORDER BY name", [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// Neue benutzerdefinierte Übung erstellen
app.post('/api/exercises', (req, res) => {
    const { name, muscle_group } = req.body;
    if (!name || !muscle_group) return res.status(400).json({ error: "Fehlende Daten" });
    
    // Default 90s Pause für Custom Exercises
    db.run(`INSERT INTO exercises (name, muscle_group, default_rest_seconds) VALUES (?, ?, 90)`, 
        [name, muscle_group], 
        function(err) {
            if (err) return res.status(500).json({ error: err.message });
            res.json({ id: this.lastID, name: name, muscle_group: muscle_group });
        }
    );
});

// === 2. LOGGER: Training speichern ===

// Set speichern
app.post('/api/workouts', (req, res) => {
    const { exercise_id, weight_kg, reps, set_type, notes } = req.body;
    
    // Validierung
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

// Set löschen
app.delete('/api/workouts/:id', (req, res) => {
    db.run(`DELETE FROM workouts WHERE id = ?`, req.params.id, function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ deleted: this.changes });
    });
});

// === 3. STATISTIKEN & ANALYSE ===

// Verlauf einer Übung laden (Filtert Warmup-Sätze raus!)
app.get('/api/history/:exerciseId', (req, res) => {
    const sql = `SELECT * FROM workouts WHERE exercise_id = ? AND set_type != 'warmup' ORDER BY date ASC`;
    db.all(sql, [req.params.exerciseId], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// Dashboard: Wöchentliche Aktivität (Sets pro Tag)
app.get('/api/dashboard/weekly', (req, res) => {
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

// Personal Record (PR) abrufen
app.get('/api/stats/pr/:exerciseId', (req, res) => {
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

// Muskel-Verteilung (Pie Chart Daten)
app.get('/api/stats/distribution', (req, res) => {
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

// GOD MODE: Ranking System
app.get('/api/stats/ranking/:exerciseId', (req, res) => {
    // 1. Hole Übungsnamen und User MAX
    const sql = `
        SELECT e.name, MAX(w.weight_kg) as max_weight 
        FROM exercises e 
        LEFT JOIN workouts w ON e.id = w.exercise_id 
        WHERE e.id = ? AND w.set_type != 'warmup'
    `;
    
    db.get(sql, [req.params.exerciseId], (err, userRecord) => {
        if (err) return res.status(500).json({ error: err.message });
        
        // Kein Record vorhanden?
        if (!userRecord || !userRecord.max_weight) {
            return res.json({ rank: "Unrated", percentile: "-", icon: "grey_circle" });
        }

        // 2. Suche passende Standards
        db.get("SELECT * FROM strength_standards WHERE exercise_name = ?", [userRecord.name], (err, std) => {
            if (err) return res.status(500).json({ error: err.message });
            
            // Keine Standards für diese spezielle Übung?
            if (!std) {
                return res.json({ rank: "Custom", percentile: "N/A", icon: "blue_circle" });
            }

            const w = userRecord.max_weight;
            let result = { rank: "Beginner", percentile: "Top 95%", icon: "bronze_medal" };

            // Ranking Logik
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

// === 4. ROUTINEN & PLANS ===

// Routine erstellen
app.post('/api/routines', (req, res) => {
    const { name } = req.body;
    db.run(`INSERT INTO routines (name) VALUES (?)`, [name], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID, name: name });
    });
});

// Alle Routinen laden
app.get('/api/routines', (req, res) => {
    db.all("SELECT * FROM routines", [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// Übung zur Routine hinzufügen
app.post('/api/routines/add-exercise', (req, res) => {
    const { routine_id, exercise_id } = req.body;
    db.run(`INSERT INTO routine_exercises (routine_id, exercise_id) VALUES (?, ?)`, 
        [routine_id, exercise_id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ status: "ok" });
    });
});

// Details einer Routine laden (inkl. Übungen)
app.get('/api/routines/:id', (req, res) => {
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

// === 5. KÖRPERDATEN (Measurements) ===

app.post('/api/measurements', (req, res) => {
    const { type, value } = req.body; // z.B. type='weight', value=80.5
    const date = new Date().toISOString();
    db.run(`INSERT INTO measurements (type, value, date) VALUES (?, ?, ?)`, 
        [type, value, date], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ id: this.lastID });
    });
});

app.get('/api/measurements/:type', (req, res) => {
    db.all(`SELECT * FROM measurements WHERE type = ? ORDER BY date ASC`, 
        [req.params.type], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// Server Start (0.0.0.0 für Emulator Support)
app.listen(port, '0.0.0.0', () => {
    console.log(`IronLog Backend läuft auf Port ${port} (MASTER EDITION)`);
    console.log(`-> Für Android Emulator: http://10.0.2.2:${port}/api/...`);
});