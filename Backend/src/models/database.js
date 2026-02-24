const sqlite3 = require('sqlite3').verbose();

const db = new sqlite3.Database('./ironlog.db', (err) => {
    if (err) {
        console.error(err.message);
    } else {
        console.log('Verbunden mit der IronLog Datenbank (FULL MASTER EDITION).');
    }
});

db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        default_rest_seconds INTEGER DEFAULT 90
    )`);

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

    db.run(`CREATE TABLE IF NOT EXISTS routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS routine_exercises (
        routine_id INTEGER,
        exercise_id INTEGER,
        FOREIGN KEY (routine_id) REFERENCES routines (id),
        FOREIGN KEY (exercise_id) REFERENCES exercises (id)
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL, 
        value REAL NOT NULL,
        date TEXT
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS strength_standards (
        exercise_name TEXT PRIMARY KEY,
        beginner REAL,
        novice REAL,
        intermediate REAL,
        advanced REAL,
        elite REAL
    )`);

    db.get("SELECT count(*) as count FROM exercises", (err, row) => {
        if (row && row.count === 0) {
            console.log("Datenbank ist leer. Starte vollständiges Seeding...");
            
            const insertEx = 'INSERT INTO exercises (name, muscle_group, default_rest_seconds) VALUES (?,?,?)';
            const insertStd = 'INSERT INTO strength_standards (exercise_name, beginner, novice, intermediate, advanced, elite) VALUES (?,?,?,?,?,?)';
            
            db.serialize(() => {
                db.run("BEGIN TRANSACTION");

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

                db.run(insertEx, ['Overhead Press (Military Press)', 'Shoulders', 180]);
                db.run(insertEx, ['Seated Dumbbell Press', 'Shoulders', 120]);
                db.run(insertEx, ['Arnold Press', 'Shoulders', 90]);
                db.run(insertEx, ['Lateral Raises (Dumbbell)', 'Shoulders', 60]);
                db.run(insertEx, ['Lateral Raises (Cable)', 'Shoulders', 60]);
                db.run(insertEx, ['Front Raises', 'Shoulders', 60]);
                db.run(insertEx, ['Reverse Flyes', 'Shoulders', 60]);
                db.run(insertEx, ['Upright Row', 'Shoulders', 90]);

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

                db.run(insertEx, ['Plank', 'Core', 60]);
                db.run(insertEx, ['Crunches', 'Core', 60]);
                db.run(insertEx, ['Leg Raises (Hanging)', 'Core', 90]);
                db.run(insertEx, ['Russian Twist', 'Core', 60]);
                db.run(insertEx, ['Ab Wheel Rollout', 'Core', 90]);
                db.run(insertEx, ['Cable Crunch', 'Core', 60]);

                db.run(insertEx, ['Running (Treadmill)', 'Cardio', 0]);
                db.run(insertEx, ['Cycling', 'Cardio', 0]);
                db.run(insertEx, ['Rowing Machine', 'Cardio', 0]);
                db.run(insertEx, ['Elliptical', 'Cardio', 0]);
                db.run(insertEx, ['Farmer’s Walk', 'Full Body', 90]);

                db.run(insertStd, ['Bench Press (Barbell)', 40, 60, 85, 110, 140]);
                db.run(insertStd, ['Squat (Barbell High Bar)', 60, 85, 110, 150, 190]);
                db.run(insertStd, ['Deadlift (Conventional)', 70, 100, 140, 190, 240]);
                db.run(insertStd, ['Overhead Press (Military Press)', 25, 40, 55, 75, 95]);
                db.run(insertStd, ['Pull-ups', 1, 5, 12, 20, 30]); 

                db.run("COMMIT");
            });
            console.log("-> 75+ Übungen und Standards erfolgreich geladen!");
        }
    });
});

module.exports = db;