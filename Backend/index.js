const express = require('express');
const cors = require('cors');

const app = express();
const port = 3000;

// Middleware
app.use(express.json());
app.use(cors());

// Services (Routen) importieren
const exerciseService = require('./src/services/exerciseService');
const workoutService = require('./src/services/workoutService');
const statsService = require('./src/services/statsService');
const routineService = require('./src/services/routineService');
const measurementService = require('./src/services/measurementService');

// Routen registrieren
app.use('/api', exerciseService);
app.use('/api', workoutService);
app.use('/api', statsService);
app.use('/api', routineService);
app.use('/api', measurementService);

// Server Start
app.listen(port, '0.0.0.0', () => {
    console.log(`IronLog Backend läuft auf Port ${port} (MASTER EDITION)`);
    console.log(`-> Für Android Emulator: http://10.0.2.2:${port}/api/...`);
});