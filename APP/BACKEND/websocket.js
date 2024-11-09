const WebSocket = require('ws');
const { handleWebSocketConnection } = require('./websocketHandler');
const { wsConnections, ClientConnections, clients, OCPPResponseMap, meterValuesMap, sessionFlags, charging_states, startedChargingSet, chargingSessionID, chargerStartTime, chargerStopTime } = require('./MapModules');

// initialize websocket connection
const initializeWebSocket = (server, ClientWebSocketServer) => {
    const wss = new WebSocket.Server({ server, maxListeners: 1000, perMessageDeflate: true });
    const ClientWss = new WebSocket.Server({ server: ClientWebSocketServer });

    handleWebSocketConnection(WebSocket, wss, ClientWss, wsConnections, ClientConnections, clients, OCPPResponseMap, meterValuesMap, sessionFlags, charging_states, startedChargingSet, chargingSessionID, chargerStartTime, chargerStopTime);
};

module.exports = { initializeWebSocket, 
                    wsConnections, 
                    ClientConnections, 
                    clients, 
                    OCPPResponseMap, 
                    meterValuesMap
                };