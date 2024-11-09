const database = require('../../db');
const logger = require('../../logger');
const { wsConnections } = require('../../MapModules.js');

// Search Charger and Get Configuration
async function searchCharger(req, res) {
    try {
        const { searchChargerID: ChargerID , Username ,user_id } = req.body;
        const db = await database.connectToDatabase();
        const evDetailsCollection = db.collection('charger_details');
        const userCollection = db.collection('users');
        const socketGunConfigCollection = db.collection('socket_gun_config');

        const chargerDetails = await evDetailsCollection.findOne({ charger_id: ChargerID,  status: true });

        // if(chargerDetails.assigned_association_id === null){
        //     const errorMessage = 'Device ID not found !';
        //     return res.status(404).json({ message: errorMessage });
        // }

        if (!chargerDetails || chargerDetails.charger_accessibility === null) {
            const errorMessage = 'Device ID not found !';
            return res.status(404).json({ message: errorMessage });
        }

        const userDetails = await userCollection.findOne({ user_id: user_id });

        // check user details available or unavailable
        if(userDetails){
            // check user status true or false
            if(userDetails.status === true){
                const socketGunConfig = await socketGunConfigCollection.findOne({ charger_id: ChargerID }); // fetch total connector id's
                //check assigned association id is null value in users 
                if(userDetails.assigned_association === null){
                    //check charger is in public or private 1 or 2
                    if(chargerDetails.charger_accessibility === 1){ //allow only public chargers
                        res.status(200).json({ status: 'Success', socketGunConfig });
                    }else{
                        const errorMessage = "Access Denied - This charger is private charger !"
                        console.log(errorMessage);
                        res.status(404).json({ status: 'Failed', message: errorMessage });
                    }
                }else{
                    //check charger association and user association is matched or un matched if its matched user can access that association private chargers
                    if(chargerDetails.assigned_association_id === userDetails.assigned_association){
                        res.status(200).json({ status: 'Success', socketGunConfig });
                    }else{
                        //check charger is in public or private 1 or 2
                        if(chargerDetails.charger_accessibility === 1){ //allow only public chargers
                            res.status(200).json({ status: 'Success', socketGunConfig });
                        }else{
                            const errorMessage = "Access Denied - This charger is private charger !"
                            console.log(errorMessage);
                            res.status(404).json({ status: 'Failed', message: errorMessage });
                        } 
                    }
                }
            }else{
                const errorMessage = "User is Deactivated ! Please contact admin."
                console.log(errorMessage);
                res.status(404).json({ status: 'Failed', message: errorMessage });
            }
        }else{
            const errorMessage = "Error in fetch user details"
            console.log(errorMessage);
        }

    } catch (error) {
        console.error('Error searching for charger:', error);
        const errorMessage = 'Internal Server Error';
        return res.status(500).json({ message: errorMessage });
    }
}

// Update Connector User
async function updateConnectorUser(req, res) {
    try {
        const { searchChargerID: ChargerID, Username: user, user_id, connector_id } = req.body;
        const db = await database.connectToDatabase();
        const evDetailsCollection = db.collection('charger_details');
        const usersCollection = db.collection('users');
        const socketGunConfigCollection = db.collection('socket_gun_config');
        const chargerStatusCollection = db.collection('charger_status');

        const chargerDetails = await evDetailsCollection.findOne({ charger_id: ChargerID, status: true });
        const socketGunConfig = await socketGunConfigCollection.findOne({ charger_id: ChargerID });

        // if (!chargerDetails) {
        //     const errorMessage = 'Device ID not found!';
        //     return res.status(404).json({ message: errorMessage });
        // }

        const connectorField = `current_or_active_user_for_connector_${connector_id}`;
        if (!chargerDetails.hasOwnProperty(connectorField)) {
            const errorMessage = 'Invalid connector ID!';
            return res.status(400).json({ message: errorMessage });
        }

        if (chargerDetails[connectorField] && user !== chargerDetails[connectorField]) {
            const errorMessage = 'Connector is already in use!';
            return res.status(400).json({ message: errorMessage });
        }

        const userRecord = await usersCollection.findOne({ user_id: user_id });

        // if (!userRecord) {
        //     const errorMessage = 'User not found';
        //     return res.status(404).json({ message: errorMessage });
        // }

        const walletBalance = userRecord.wallet_bal;
        if (walletBalance < 100) {
            const errorMessage = 'Your wallet balance is not enough to charge (minimum 100 Rs required)';
            return res.status(400).json({ message: errorMessage });
        }

        // if (chargerDetails.charger_accessibility === 1) {
        //     if (chargerDetails.AssignedUser !== user) {
        //         const errorMessage = 'Access Denied: You do not have permission to use this private charger.';
        //         return res.status(400).json({ message: errorMessage });
        //     }
        // } else {
            
        // }

        // Update the user field in the chargerDetails
        let currect_user = {};
        currect_user[connectorField] = user;

        const connectorIdTypeField = `connector_${connector_id}_type`;
        const connectorTypeValue = socketGunConfig[connectorIdTypeField];
        if (connectorTypeValue === 1) { // Assuming 1 stands for 'socket'
            const fetchChargerStatus = await chargerStatusCollection.findOne({ charger_id: ChargerID, connector_id: connector_id , connector_type: 1});

            if (fetchChargerStatus && fetchChargerStatus.charger_status !== 'Charging' && fetchChargerStatus.charger_status !== 'Preparing') {

                const result = await sendPreparingStatus(wsConnections, ChargerID, connector_id);

                if (!result) {
                    const errorMessage = 'Device not connected to the server';
                    return res.status(500).json({ message: errorMessage });
                }
            }
        }

        const updateResult = await evDetailsCollection.updateOne(
            { charger_id: ChargerID },
            { $set: currect_user }
        );

        if (updateResult.modifiedCount !== 1) {
            console.log('Failed to update current_or_active username for the connector');
        }

        // Respond with the charger details
        res.status(200).json({ message: 'Success' });

    } catch (error) {
        console.error('Error updating connector user:', error);
        const errorMessage = 'Internal Server Error';
        return res.status(500).json({ message: errorMessage });
    }
}

const sendPreparingStatus = async (wsConnections, Identifier, connectorId) => {
    const id = Identifier;
    const sendTo = wsConnections.get(Identifier);
    const db = await database.connectToDatabase();
    const evDetailsCollection = db.collection('charger_details');
    const chargerDetails = await evDetailsCollection.findOne({ charger_id: id });

    if (!chargerDetails) {
        const errorMessage = 'Charger ID not found in the database.';
        console.error(errorMessage);
        return false;
    }

    const vendorId = chargerDetails.vendor; // Fetch vendorId from charger_details collection

    let response;
    if (connectorId == 1) {
        response = [2, Identifier, "DataTransfer", {
            "vendorId": vendorId, // Use fetched vendorId
            "messageId": "TEST",
            "data": "Preparing",
            "connectorId": connectorId,
        }];
    }

    if (sendTo) {
        await sendTo.send(JSON.stringify(response));
        let WS_MSG = `ChargerID: ${id} - SendingMessage: ${JSON.stringify(response)}`;
        logger.info(WS_MSG);
        console.log(WS_MSG);
        return true;
    } else {
        return false;
    }
};

// FILTER CHARGERS
// getRecentSessionDetails
async function getRecentSessionDetails(req, res) {
    try {
        const { user_id } = req.body;
        if (!user_id) {
            return res.status(401).json({ message: 'User ID is undefined!' });
        }

        const db = await database.connectToDatabase();
        const collection = db.collection('device_session_details');
        const chargerDetailsCollection = db.collection('charger_details');
        const chargerStatusCollection = db.collection('charger_status');
        const usersCollection = db.collection('users');
        const financeDetailsCollection = db.collection('finance_details');

        // Fetch the user details to get the username
        const userRecord = await usersCollection.findOne({ user_id: user_id });
        if (!userRecord) {
            return res.status(404).json({ message: 'User not found' });
        }

        const username = userRecord.username;

        // Fetch all charging sessions for the user
        const sessions = await collection.find({ user: username, stop_time: { $ne: null } }).sort({ stop_time: -1 }).toArray();

        if (!sessions || sessions.length === 0) {
            return res.status(404).json({ message: 'No Charger entries' });
        }

        // Filter to get the most recent session per charger_id, connector_id, and connector_type
        const recentSessionsByConnector = sessions.reduce((acc, session) => {
            const key = `${session.charger_id}-${session.connector_id}-${session.connector_type}`;
            if (!acc[key] || new Date(acc[key].stop_time) < new Date(session.stop_time)) {
                acc[key] = session;
            }
            return acc;
        }, {});

        // Convert the result object to an array
        const recentSessions = Object.values(recentSessionsByConnector);

        // Join the recent sessions with charger details, charger status, and unit price
        const detailedSessions = await Promise.all(recentSessions.map(async (session) => {
            const details = await chargerDetailsCollection.findOne({ charger_id: session.charger_id });
            const status = await chargerStatusCollection.findOne({ charger_id: session.charger_id, connector_id: session.connector_id });

            // Exclude sessions where the charger status is not true
            if (details?.status !== true) {
                return null; // Skip this session if the status is not true
            }

            // Find the finance ID related to the charger
            const financeId = details?.finance_id;
            let unitPrice = null;

            if (financeId) {
                // Fetch the finance record using the finance ID
                const financeRecord = await financeDetailsCollection.findOne({ finance_id: financeId });

                if (financeRecord) {
                    // Calculate the total percentage from finance details
                    const totalPercentage = [
                        financeRecord.app_charges,
                        financeRecord.other_charges,
                        financeRecord.parking_charges,
                        financeRecord.rent_charges,
                        financeRecord.open_a_eb_charges,
                        financeRecord.open_other_charges
                    ].reduce((sum, charge) => sum + parseFloat(charge || 0), 0);

                    // Calculate the unit price based on the finance record
                    const pricePerUnit = parseFloat(financeRecord.eb_charges || 0);
                    const totalPrice = pricePerUnit + (pricePerUnit * totalPercentage / 100);

                    // Format the total price to 2 decimal places
                    unitPrice = totalPrice.toFixed(2);
                }
            }

            return {
                ...session,
                details,
                status,
                unit_price: unitPrice // Append the unit price to the session details
            };
        }));

        // Filter out any null values resulting from the status check
        const filteredSessions = detailedSessions.filter(session => session !== null);

        // Return the filtered session data
        return res.status(200).json({ data: filteredSessions });
    } catch (error) {
        console.error(error);
        return res.status(500).send({ message: 'Internal Server Error' });
    }
}

// FETCH ALL CHARGERS WITH STATUS AND UNIT PRICE
async function getAllChargersWithStatusAndPrice(req, res) {
    try {
        const { user_id } = req.body;

        const db = await database.connectToDatabase();
        const userDetailsCollection = db.collection('users');
        const chargerDetailsCollection = db.collection('charger_details');
        const chargerStatusCollection = db.collection('charger_status');
        const financeDetailsCollection = db.collection('finance_details');

        // Fetch the user's assigned association
        const user = await userDetailsCollection.findOne({ user_id: user_id });

        if (!user) {
            return res.status(404).json({ message: 'User not found or assigned association is missing' });
        }

        const userAssignedAssociation = user.assigned_association;
        let allChargers;

        // Fetch all chargers where charger_accessibility is not null and the assigned_association_id matches the user's assigned_association
        if(userAssignedAssociation === null){
            allChargers = await chargerDetailsCollection.find({
                charger_accessibility: 1,
                assigned_association_id: { $ne: null },
                status: true
            }).toArray();
        }else{
            // Fetch documents with charger_accessibility 1
            const chargersAccessibilityOne = await chargerDetailsCollection.find({
                //assigned_association_id: userAssignedAssociation,
                charger_accessibility: 1, // Fetch all documents with charger_accessibility 1
                assigned_association_id: { $ne: null },
                status: true
            }).toArray();

            // Fetch documents with charger_accessibility 2 only if assigned_association_id matches
            const chargersAccessibilityTwo = await chargerDetailsCollection.find({
                charger_accessibility: 2, // Fetch documents with charger_accessibility 2
                status: true,
                $or: [
                    { assigned_association_id: userAssignedAssociation }, // If association matches
                    { assigned_association_id: { $exists: false } } // or if association_id is not set
                ]
            }).toArray();

            // Combine results
            allChargers = [...chargersAccessibilityOne, ...chargersAccessibilityTwo];

        }
        
        // Fetch detailed information for each charger, including its status and unit price
        const detailedChargers = await Promise.all(allChargers.map(async (charger) => {
            const chargerId = charger.charger_id;

            // Fetch charger status
            const status = await chargerStatusCollection.find({ charger_id: chargerId }).toArray();

            // Find the finance ID related to the charger
            const financeId = charger.finance_id;

            // Fetch the unit price using the finance ID
            let unitPrice = null;
            if (financeId) {
                // Fetch the finance record using the finance ID
                const financeRecord = await financeDetailsCollection.findOne({ finance_id: financeId });
        
                if (financeRecord) {
                    // Calculate the total percentage from finance details
                    const totalPercentage = [
                        financeRecord.app_charges,
                        financeRecord.other_charges,
                        financeRecord.parking_charges,
                        financeRecord.rent_charges,
                        financeRecord.open_a_eb_charges,
                        financeRecord.open_other_charges
                    ].reduce((sum, charge) => sum + parseFloat(charge || 0), 0);
        
                    // Calculate the unit price based on the finance record
                    const pricePerUnit = parseFloat(financeRecord.eb_charges || 0);
                    const totalPrice = pricePerUnit + (pricePerUnit * totalPercentage / 100);
        
                    // Format the total price to 2 decimal places
                    unitPrice = totalPrice.toFixed(2);
                }
            }

            return {
                ...charger,
                status: status.length > 0 ? status : null,
                unit_price: unitPrice // Append the unit price to the charger details
            };
        }));

        // Return the detailed charger data
        return res.status(200).json({ data: detailedChargers });
    } catch (error) {
        console.error(error);
        return res.status(500).send({ message: 'Internal Server Error' });
    }
}



module.exports = { 
    //SEARCH CHARGER
    searchCharger,
    updateConnectorUser,
    //FILTER CHARGERS
    getRecentSessionDetails,
    getAllChargersWithStatusAndPrice,
};
