const express = require('express');
const router = express.Router();
const database = require('../../db');

router.get('/checkChargerID', async function(req, res) {
    try {
        const charger_id = req.query.charger_id;
        if (!charger_id) {
            const errorMessage = 'Charger ID is not found !';
            return res.status(401).json({ message: errorMessage });
        }

        const db = await database.connectToDatabase();
        const Collection = db.collection('device_session_details');
        const charger_table = db.collection('charger_details');

        const checkChargerID = await charger_table.findOne({"charger_id" : charger_id});

        if(!checkChargerID){
            const errorMessage = 'Charger ID is not available !';
            return res.status(401).json({ message: errorMessage });
        }

        const result = await Collection.find({ charger_id: charger_id, stop_time: { $ne: null } }).sort({ stop_time: -1 }).toArray();

        if (!result || result.length === 0) {
            const errorMessage = 'ChargerSessionDetails - No record found !';
            return res.status(404).json({ message: errorMessage });
        }

        return res.status(200).json({ value: result });
    } catch (error) {
        console.error(error);
        res.status(500).send({ message: 'Internal Server Error' });
    }
});

// Export the router
module.exports = router;