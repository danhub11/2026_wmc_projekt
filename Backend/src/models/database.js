const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Pfad zur Datenbank im Hauptverzeichnis
const dbPath = path.resolve(__dirname, '../../ironlog.db');

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error(err.message);
    } else {
        console.log('Verbunden mit der IronLog Datenbank (MODULAR EDITION).');
    }
});

db.serialize(() => {
    // 1. Tabelle: Übungen (Update: description, tips, image_url)
    db.run(`CREATE TABLE IF NOT EXISTS exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        default_rest_seconds INTEGER DEFAULT 90,
        description TEXT DEFAULT '',
        tips TEXT DEFAULT '',
        image_url TEXT DEFAULT ''
    )`);

    // 2. Tabelle: Workouts
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

    // 3. Tabelle: Routinen
    db.run(`CREATE TABLE IF NOT EXISTS routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
    )`);

    // 4. Tabelle: Routine-Inhalt
    db.run(`CREATE TABLE IF NOT EXISTS routine_exercises (
        routine_id INTEGER,
        exercise_id INTEGER,
        FOREIGN KEY (routine_id) REFERENCES routines (id),
        FOREIGN KEY (exercise_id) REFERENCES exercises (id)
    )`);

    // 5. Tabelle: Körperdaten
    db.run(`CREATE TABLE IF NOT EXISTS measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL, 
        value REAL NOT NULL,
        date TEXT
    )`);

    // 6. Tabelle: Kraftstandards
    db.run(`CREATE TABLE IF NOT EXISTS strength_standards (
        exercise_name TEXT PRIMARY KEY,
        beginner REAL,
        novice REAL,
        intermediate REAL,
        advanced REAL,
        elite REAL
    )`);

    // --- SEEDING ---
    db.get("SELECT count(*) as count FROM exercises", (err, row) => {
        if (row && row.count === 0) {
            console.log("Datenbank ist leer. Starte vollständiges Seeding...");
            
            const insertEx = 'INSERT INTO exercises (name, muscle_group, default_rest_seconds, description, tips, image_url) VALUES (?,?,?,?,?,?)';
            const addEx = (name, group, rest, desc = 'Keine Beschreibung verfügbar.', tips = 'Keine Tipps hinterlegt.', img = 'https://via.placeholder.com/400x200.png?text=IronLog+Exercise') => {
                db.run(insertEx, [name, group, rest, desc, tips, img]);
            };

            const insertStd = 'INSERT INTO strength_standards (exercise_name, beginner, novice, intermediate, advanced, elite) VALUES (?,?,?,?,?,?)';
            
            db.serialize(() => {
                db.run("BEGIN TRANSACTION");

                // BRUST (Chest)
                addEx('Bench Press (Barbell)', 'Chest', 180, 'Lege dich flach auf die Bank. Greife die Hantel etwas weiter als schulterbreit. Senke das Gewicht kontrolliert zur unteren Brust ab und drücke es explosiv nach oben.', 'Füße fest auf dem Boden, leichter Bogen im unteren Rücken, Schulterblätter zusammenziehen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Bench+Press');
                addEx('Bench Press (Dumbbell)', 'Chest', 120, 'Lege dich mit einer Kurzhantel in jeder Hand auf eine flache Bank. Drücke die Hanteln über der Brust zusammen und senke sie kontrolliert ab.', 'Hanteln nicht oben zusammenschlagen. Volle Dehnung in der Brustmuskulatur spüren.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=DB+Bench+Press');
                addEx('Incline Bench Press (Barbell)', 'Chest', 180, 'Bank auf 30-45 Grad einstellen. Hantel greifen und kontrolliert zur oberen Brust absenken.', 'Fokus auf den oberen Teil der Brustmuskulatur.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Incline+Bench');
                addEx('Incline Bench Press (Dumbbell)', 'Chest', 120, 'Bank auf 30-45 Grad. Kurzhanteln über der oberen Brust drücken.', 'Schultern hinten lassen, nicht nach vorne einrunden.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Incline+DB+Press');
                addEx('Decline Bench Press', 'Chest', 120, 'Auf einer negativ geneigten Bank die Langhantel zur unteren Brust absenken.', 'Gute Alternative, um die Schultern zu schonen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Decline+Bench');
                addEx('Chest Press Machine', 'Chest', 90, 'Setze dich an die Maschine, Griffe auf Brusthöhe. Drücke das Gewicht nach vorne.', 'Rücken flach am Polster halten.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Chest+Press+Machine');
                addEx('Push-ups', 'Chest', 60, 'Stütze dich mit den Händen schulterbreit ab, der Körper bildet eine gerade Linie. Senke den Körper ab, bis die Brust fast den Boden berührt.', 'Körperspannung halten, Ellbogen nicht zu weit nach außen abspreizen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Push-ups');
                addEx('Weighted Push-ups', 'Chest', 90, 'Liegestütze mit Zusatzgewicht auf dem Rücken.', 'Zusatzgewicht sicher positionieren lassen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Weighted+Push-ups');
                addEx('Dips (Chest Focus)', 'Chest', 120, 'An den Dip-Barren abstützen. Oberkörper leicht nach vorne beugen und absenken, bis eine Dehnung in der Brust spürbar ist.', 'Ellbogen leicht nach außen ausstellen, um die Brust stärker zu belasten.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Chest+Dips');
                addEx('Cable Flyes (High-to-Low)', 'Chest', 60, 'Kabelzug von oben nach unten vor dem Körper zusammenführen.', 'Arme leicht gebeugt lassen, Bewegung kommt aus dem Schultergelenk.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=High+Cable+Flyes');
                addEx('Cable Flyes (Low-to-High)', 'Chest', 60, 'Kabelzug von unten nach oben vor der oberen Brust zusammenführen.', 'Fokus auf die obere Brustmuskulatur.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Low+Cable+Flyes');
                addEx('Pec Deck / Butterfly', 'Chest', 60, 'An der Maschine sitzen und die Arme vor der Brust zusammenführen.', 'Bewegung kontrolliert ausführen, Schwung vermeiden.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Butterfly');

                // RÜCKEN (Back)
                addEx('Deadlift (Conventional)', 'Back', 180, 'Stelle dich hüftbreit vor die Hantel. Greife die Stange, halte den Rücken gerade und die Brust oben. Hebe das Gewicht durch Streckung von Hüfte und Beinen.', 'Rücken niemals einrunden! Stange nah am Körper führen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Deadlift');
                addEx('Deadlift (Sumo)', 'Back', 180, 'Breiter Stand, Fußspitzen zeigen nach außen. Hantel im schulterbreiten Griff greifen und heben.', 'Hüfte nah an der Stange halten, Oberkörper aufrecht.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Sumo+Deadlift');
                addEx('Pull-ups', 'Back', 120, 'Klimmzugstange im Obergriff greifen. Körper hochziehen, bis das Kinn über der Stange ist.', 'Ohne Schwung arbeiten, kontrolliert absenken.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Pull-ups');
                addEx('Chin-ups', 'Back', 120, 'Klimmzugstange im Untergriff greifen. Körper hochziehen.', 'Fokus liegt hier stärker auf dem Bizeps und den Lats.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Chin-ups');
                addEx('Lat Pulldown (Wide Grip)', 'Back', 90, 'Stange breit greifen und zur oberen Brust ziehen.', 'Oberkörper leicht nach hinten lehnen, Brust rausdrücken.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Lat+Pulldown');
                addEx('Lat Pulldown (Close Grip)', 'Back', 90, 'Engen Griff (V-Griff) verwenden und zur Brust ziehen.', 'Ellbogen nah am Körper führen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Close+Grip+Pulldown');
                addEx('Barbell Row', 'Back', 120, 'Oberkörper vorbeugen, Rücken gerade. Langhantel zum Bauchnabel ziehen.', 'Rückenstabilität ist essenziell. Nicht aufrichten beim Ziehen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Barbell+Row');
                addEx('Pendlay Row', 'Back', 120, 'Wie Langhantelrudern, aber das Gewicht wird nach jeder Wiederholung auf dem Boden abgelegt.', 'Explosive Zugbewegung, strikte Form.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Pendlay+Row');
                addEx('Dumbbell Row', 'Back', 90, 'Auf einer Bank abstützen. Kurzhantel eng am Körper nach oben ziehen.', 'Rückenmuskulatur bewusst kontrahieren.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Dumbbell+Row');
                addEx('Seated Cable Row', 'Back', 90, 'Am Kabelzug sitzen, Griff zum unteren Bauch ziehen.', 'Schultern hinten lassen, nicht nach vorne ziehen lassen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Seated+Row');
                addEx('T-Bar Row', 'Back', 120, 'Langhantel in eine Ecke stellen oder Maschine nutzen. Gewicht zur Brust ziehen.', 'Hervorragend für die Rückendicke.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=T-Bar+Row');
                addEx('Face Pulls', 'Back', 60, 'Kabelzug mit Seil auf Kopfhöhe. Seil in Richtung des Gesichts ziehen.', 'Wichtig für die hintere Schulter und Rotatorenmanschette.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Face+Pulls');
                addEx('Shrugs (Barbell)', 'Back', 90, 'Langhantel halten und Schultern in Richtung der Ohren hochziehen.', 'Arme gestreckt lassen, nicht mit dem Bizeps ziehen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Barbell+Shrugs');
                addEx('Shrugs (Dumbbell)', 'Back', 90, 'Mit Kurzhanteln seitlich am Körper die Schultern heben.', 'Kein Kreisen der Schultern, nur gerade hoch und runter.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Dumbbell+Shrugs');
                addEx('Hyperextensions', 'Back', 60, 'Im Gerät einklemmen und Oberkörper aufrichten.', 'Rücken nicht überstrecken, neutrale Wirbelsäule beibehalten.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Hyperextensions');

                // BEINE (Legs)
                addEx('Squat (Barbell High Bar)', 'Legs', 180, 'Lege die Langhantel auf der hinteren Schultermuskulatur ab. Gehe kontrolliert in die Hocke, bis die Oberschenkel mindestens parallel zum Boden sind. Drücke dich aus den Fersen wieder hoch.', 'Knie in Richtung der Zehenspitzen drücken, Brust aufrecht halten.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Squat');
                addEx('Squat (Barbell Low Bar)', 'Legs', 180, 'Langhantel tiefer auf den hinteren Schultern ablegen. Hüfte stärker nach hinten schieben.', 'Ermöglicht oft mehr Gewicht durch stärkere Einbindung der hinteren Kette.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Low+Bar+Squat');
                addEx('Front Squat', 'Legs', 150, 'Langhantel vorne auf den vorderen Schultern ablegen. Aufrecht beugen.', 'Fokusiert den Quadrizeps und erfordert hohe Rumpfstabilität.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Front+Squat');
                addEx('Goblet Squat', 'Legs', 90, 'Eine Kurzhantel oder Kettlebell vor der Brust halten und in die Hocke gehen.', 'Gute Übung zum Erlernen der Kniebeugen-Technik.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Goblet+Squat');
                addEx('Leg Press', 'Legs', 120, 'In der Maschine sitzen und das Gewicht mit den Beinen wegdrücken.', 'Knie am obersten Punkt niemals komplett durchstrecken (Lockout vermeiden).', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Leg+Press');
                addEx('Lunges (Walking)', 'Legs', 90, 'Mit Kurzhanteln Ausfallschritte nach vorne machen.', 'Hinteres Knie berührt fast den Boden. Oberkörper aufrecht.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Walking+Lunges');
                addEx('Bulgarian Split Squat', 'Legs', 120, 'Hinteren Fuß auf einer Bank ablegen. Auf einem Bein in die Hocke gehen.', 'Sehr effektiv für Quadrizeps und Gesäß. Erfordert Balance.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Split+Squat');
                addEx('Romanian Deadlift', 'Legs', 150, 'Beine leicht gebeugt. Hantel absenken, indem die Hüfte nach hinten geschoben wird.', 'Spüre die Dehnung in der Beinbeugemuskulatur. Rücken gerade halten.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Romanian+Deadlift');
                addEx('Leg Extension', 'Legs', 60, 'An der Maschine sitzen und die Beine gegen den Widerstand strecken.', 'Fokus auf maximale Kontraktion des Quadrizeps oben.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Leg+Extension');
                addEx('Leg Curl (Seated)', 'Legs', 60, 'Sitzend an der Maschine die Fersen Richtung Gesäß ziehen.', 'Isoliert die Beinbeuger.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Seated+Leg+Curl');
                addEx('Leg Curl (Lying)', 'Legs', 60, 'Auf dem Bauch liegend an der Maschine die Fersen Richtung Gesäß beugen.', 'Hüfte während der Bewegung auf dem Polster lassen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Lying+Leg+Curl');
                addEx('Calf Raises (Standing)', 'Legs', 60, 'An der Maschine stehen und sich auf die Zehenspitzen drücken.', 'Volle Range of Motion nutzen (tief dehnen, hoch drücken).', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Standing+Calf');
                addEx('Calf Raises (Seated)', 'Legs', 60, 'Sitzend an der Maschine auf die Zehenspitzen drücken.', 'Fokusiert den Schollenmuskel (Soleus).', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Seated+Calf');

                // SCHULTERN (Shoulders)
                addEx('Overhead Press (Military Press)', 'Shoulders', 180, 'Stehend die Langhantel von der vorderen Schulter über den Kopf drücken.', 'Rumpf anspannen, kein starkes Hohlkreuz bilden.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Overhead+Press');
                addEx('Seated Dumbbell Press', 'Shoulders', 120, 'Sitzend auf einer Bank Kurzhanteln über den Kopf drücken.', 'Banklehne auf ca. 75-85 Grad einstellen, um die Schultern zu schützen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=DB+Shoulder+Press');
                addEx('Arnold Press', 'Shoulders', 90, 'Kurzhanteln vor dem Gesicht halten (Handflächen zu dir). Beim Drücken eindrehen.', 'Beansprucht alle drei Schulterköpfe.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Arnold+Press');
                addEx('Lateral Raises (Dumbbell)', 'Shoulders', 60, 'Kurzhanteln seitlich am Körper hochheben, bis die Arme parallel zum Boden sind.', 'Leichte Beugung im Ellbogen. Kleiner Finger zeigt oben leicht nach oben.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Lateral+Raises');
                addEx('Lateral Raises (Cable)', 'Shoulders', 60, 'Seitheben am unteren Kabelzug für konstante Spannung.', 'Bewegung kontrolliert ausführen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Cable+Lateral+Raises');
                addEx('Front Raises', 'Shoulders', 60, 'Gewicht vor dem Körper mit gestreckten Armen anheben.', 'Nicht schwingen. Kontrolliert absenken.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Front+Raises');
                addEx('Reverse Flyes', 'Shoulders', 60, 'Oberkörper vorbeugen und Arme seitlich anheben.', 'Fokus auf die hintere Schultermuskulatur.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Reverse+Flyes');
                addEx('Upright Row', 'Shoulders', 90, 'Langhantel oder SZ-Stange nah am Körper hochziehen.', 'Ellbogen führen die Bewegung an. Griffbreite anpassen bei Schmerzen im Handgelenk.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Upright+Row');

                // ARME (Arms)
                addEx('Barbell Curl', 'Arms', 90, 'Langhantel im Untergriff halten und beugen.', 'Ellbogen am Körper fixieren, nicht mitschwingen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Barbell+Curl');
                addEx('Dumbbell Curl', 'Arms', 90, 'Kurzhanteln abwechselnd oder gleichzeitig beugen.', 'Volle Dehnung im unteren Punkt nutzen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Dumbbell+Curl');
                addEx('Hammer Curl', 'Arms', 90, 'Kurzhanteln im neutralen Griff (Daumen zeigen nach oben) beugen.', 'Fokusiert den Brachialis und Unterarm.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Hammer+Curl');
                addEx('Preacher Curl', 'Arms', 60, 'Bizepscurls auf einer Scott-Bank zur Isolation.', 'Arme nicht komplett durchstrecken, um Sehnenreizungen zu vermeiden.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Preacher+Curl');
                addEx('Concentration Curl', 'Arms', 60, 'Sitzend, Ellbogen an der Innenseite des Oberschenkels abstützen und curlen.', 'Fokus auf den "Peak" des Bizeps.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Concentration+Curl');
                addEx('Tricep Pushdown (Rope)', 'Arms', 60, 'Trizepsdrücken am Kabelzug mit Seil. Unten auseinanderziehen.', 'Ellbogen am Körper festpinnen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Tricep+Rope');
                addEx('Tricep Pushdown (Bar)', 'Arms', 60, 'Trizepsdrücken am Kabelzug mit einer Stange.', 'Gute Übung, um schweres Gewicht für den Trizeps zu bewegen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Tricep+Bar');
                addEx('Skullcrushers', 'Arms', 90, 'Auf dem Rücken liegend eine SZ-Stange zur Stirn absenken und wieder strecken.', 'Ellbogen zeigen nach oben, nicht zur Seite ausbrechen lassen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Skullcrushers');
                addEx('Overhead Tricep Extension', 'Arms', 90, 'Sitzend oder stehend ein Gewicht über dem Kopf absenken und strecken.', 'Sehr gut für den langen Kopf des Trizeps.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Overhead+Tricep');
                addEx('Close-Grip Bench Press', 'Arms', 120, 'Bankdrücken mit einem engen Griff (schulterbreit).', 'Fokus verlagert sich von der Brust stark auf den Trizeps.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Close+Grip+Bench');
                addEx('Tricep Dips', 'Arms', 90, 'Dips am Barren mit aufrechtem Oberkörper.', 'Gestreckt hochdrücken, um den Trizeps maximal anzuspannen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Tricep+Dips');

                // CORE (Abs)
                addEx('Plank', 'Core', 60, 'Unterarmstütz halten. Körper bildet eine gerade Linie.', 'Bauch und Gesäß fest anspannen. Nicht durchhängen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Plank');
                addEx('Crunches', 'Core', 60, 'Auf dem Rücken liegend die Schultern vom Boden abheben.', 'Nicht am Nacken ziehen. Bewegung kommt aus dem Bauch.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Crunches');
                addEx('Leg Raises (Hanging)', 'Core', 90, 'Hängend an der Stange die Beine (gestreckt oder gebeugt) anheben.', 'Schwung vermeiden, Bewegung kontrollieren.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Hanging+Leg+Raises');
                addEx('Russian Twist', 'Core', 60, 'Sitzend, Beine leicht angehoben. Oberkörper mit Gewicht von Seite zu Seite drehen.', 'Kopf folgt der Bewegung. Rumpfspannung halten.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Russian+Twist');
                addEx('Ab Wheel Rollout', 'Core', 90, 'Auf den Knien das Bauchrad nach vorne rollen und wieder zurückziehen.', 'Sehr anspruchsvoll. Kein Hohlkreuz machen!', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Ab+Wheel');
                addEx('Cable Crunch', 'Core', 60, 'Kniend vor dem Kabelzug das Seil hinter dem Nacken halten und einrollen.', 'Hüfte bleibt fixiert, nur der Oberkörper rollt sich ein.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Cable+Crunch');

                // CARDIO & FUNCTIONAL
                addEx('Running (Treadmill)', 'Cardio', 0, 'Laufen auf dem Laufband.', 'Geschwindigkeit und Steigung anpassen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Treadmill');
                addEx('Cycling', 'Cardio', 0, 'Fahren auf dem Fahrradergometer.', 'Sitzhöhe korrekt einstellen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Cycling');
                addEx('Rowing Machine', 'Cardio', 0, 'Rudern auf dem Concept2 oder ähnlichen Geräten.', 'Beinarbeit ist entscheidend. Zuerst Beine strecken, dann Arme ziehen.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Rowing');
                addEx('Elliptical', 'Cardio', 0, 'Training auf dem Crosstrainer.', 'Gelenkschonendes Cardiotraining.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Elliptical');
                addEx('Farmer’s Walk', 'Full Body', 90, 'Zwei schwere Kurzhanteln nehmen und eine Strecke gehen.', 'Brust raus, Schultern hinten, gerader Gang.', 'https://via.placeholder.com/400x200/F27A4D/ffffff.png?text=Farmers+Walk');

                db.run(insertStd, ['Bench Press (Barbell)', 40, 60, 85, 110, 140]);
                db.run(insertStd, ['Squat (Barbell High Bar)', 60, 85, 110, 150, 190]);
                db.run(insertStd, ['Deadlift (Conventional)', 70, 100, 140, 190, 240]);
                db.run(insertStd, ['Overhead Press (Military Press)', 25, 40, 55, 75, 95]);
                db.run(insertStd, ['Pull-ups', 1, 5, 12, 20, 30]);

                db.run("COMMIT");
            });
            console.log("-> 75+ Übungen und Standards erfolgreich in Module Edition geladen!");
        }
    });
});

module.exports = db;