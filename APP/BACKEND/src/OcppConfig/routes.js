const express = require('express');
const router = express.Router();
const database = require('../../db');
const { wsConnections, OCPPResponseMap } = require('../../MapModules.js');
const url = require('url');
const logger = require('../../logger');

//Fetch all action options for OCPPConfig
router.get('/GetAction', async(req, res) => {

    try {
        const db = await database.connectToDatabase();
        const collection = db.collection('ocpp_actions');

        const Data = await collection.find({}).toArray();

        // Map the database documents into the desired format
        const ResponseVal = Data.map(item => {
            return {
                action: item.action,
                payload: JSON.parse(item.payload)
            };
        });

        res.status(200).json(ResponseVal);
    } catch (error) {
        console.log("Error form GetAction - ", error);
        logger.error("Error form GetAction - ", error);
    }

})

router.get('/SendOCPPRequest', async (req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const queryParams = parsedUrl.query;
    const id = queryParams.id;
    const payload = JSON.parse(queryParams.req);
    const action = queryParams.actionBtn;

    const db = await database.connectToDatabase();
    const collection = db.collection('charger_details');

    const result = await collection.findOne({ charger_id: id });

    if (!result) {
        return res.status(404).json({ message: "Device ID not found!" });
    }

    const deviceIDToSendTo = id; // Specify the device ID to send the message to
    const wsToSendTo = wsConnections.get(deviceIDToSendTo);
    let ReqMsg = "";

    if (wsToSendTo) {
        switch (action) {
            case "GetConfiguration":
                ReqMsg = [2, "1701682466381", "GetConfiguration", payload];
                break;
            case "DataTransfer":
                ReqMsg = [2, "1701682577682", "DataTransfer", payload];
                break;
            case "UpdateFirmware":
                ReqMsg = [2, "1701682616333", "UpdateFirmware", payload];
                break;
            case "ChangeConfiguration":
                ReqMsg = [2, "1701682616334", "ChangeConfiguration", payload];
                break;
            case "ClearCache":
                ReqMsg = [2, "1701682616335", "ClearCache", ''];
                break;
            case "TriggerMessage":
                ReqMsg = [2, "1701682616336", "TriggerMessage", payload];
                break;
            case "Reset":
                ReqMsg = [2, "1701682616337", "Reset", payload];
                break;
            case "UnlockConnector":
                ReqMsg = [2, "1701682616338", "UnlockConnector", payload];
                break;
            case "RemoteStartTransaction":
                ReqMsg = [2, "1695798668459", "RemoteStartTransaction", payload];
                break;
            case "RemoteStopTransaction":
                ReqMsg = [2, "1695798668459", "RemoteStopTransaction", payload];
                break;
            case "GetDiagnostics":
                ReqMsg = [2, "1701682616340", "GetDiagnostics", payload];
                console.log(ReqMsg);
                break;
            case "ChangeAvailability":
                ReqMsg = [2, "1701682616341", "ChangeAvailability", payload];
                break;
            case "CancelReservation":
                ReqMsg = [2, "1701682616342", "CancelReservation", payload];
                break;
            case "ReserveNow":
                ReqMsg = [2, "1701682616343", "ReserveNow", payload];
                break;
            case "SendLocalList":
                ReqMsg = [2, "1701682616344", "SendLocalList", payload];
                break;
            case "GetLocalListVersion":
                ReqMsg = [2, "1701682616345", "GetLocalListVersion", payload];
                break;
            case "GetCompositeSchedule":
                ReqMsg = [2, "1701682616346", "GetCompositeSchedule", payload];
                break;
            case "ClearChargingProfile":
                ReqMsg = [2, "1701682616347", "ClearChargingProfile", payload];
                break;
            case "SetChargingProfile":
                ReqMsg = [2, "1701682616347", "SetChargingProfile", payload];
                break;
            default:
                return res.status(400).json({ message: "Invalid action!" }); // Handle unexpected action
        }

        // Map the WebSocket connection to the HTTP response
        OCPPResponseMap.set(wsToSendTo, res);
        wsToSendTo.send(JSON.stringify(ReqMsg));

        console.log('Request message sent to the OCPP Request client for device ID:', deviceIDToSendTo);
        logger.info('Request message sent to the OCPP Request client for device ID:', deviceIDToSendTo);

    } else {
        // Charger ID Not Found/Available
        console.log('OCPP Request client not found for the specified device ID:', deviceIDToSendTo);
        logger.info('OCPP Request client not found for the specified device ID:', deviceIDToSendTo);
        return res.status(404).json({ message: 'OCPP Request client not found' }); // Added return
    }
});

// Export the router
module.exports = router;