import React, { useCallback, useEffect, useState } from 'react';
import useWebSocket from 'react-use-websocket';

import './Dashboard.css'

import HSVisualization from '../HSVisualization';

import { webSocketUrl } from '../../config';

const webSocketRequesters = {
    get: "Dashboard.get"
};

interface Props {
    selected: string;
    selectedExists: boolean;
}

interface JsonDashboard {
    uri: string;
    elements: Array<JsonDashboardElement>;
}

interface JsonDashboardElement {
    uri: string;
    definition: string;
    dataSources: string;
}

export default function Dashboard({ selected, selectedExists }: Props) {
    const [dashboard, setDashboard] = useState<JsonDashboard | null>();
    const { lastJsonMessage, sendJsonMessage } = useWebSocket(webSocketUrl, {
        share: true,
        shouldReconnect: () => true,
        filter: (message) => Object.values(webSocketRequesters).includes(JSON.parse(message.data).requester),
    });
    
    const sendGet = useCallback(() => {
        sendJsonMessage({
            requester: webSocketRequesters.get,
            type: "query",
            path: [
                { name: "dashboardManager" },
                { name: "getDashboard", args: [selected] },
            ]
        });
    }, [sendJsonMessage, selected]);

    useEffect(() => {
        if (selected.length > 0 && selectedExists) {
            sendGet();
        }
    }, [selected, selectedExists, sendGet]);

    useEffect(() => {
        const msg: any = lastJsonMessage;
        if (!msg) {
            return
        } else if (msg.error) { // Handle an error
            console.warn("Backend returned error: ", msg);
        } else if (msg.requester) { // Handle a response
            switch (msg.requester) {
                case webSocketRequesters.get:
                    console.log(`Received dashboard desc ${JSON.stringify(msg.result)}`);
                    setDashboard(msg.result);
                    break;
                default:
                    console.warn("Unknown requester: ", msg.requester);
                    break;
            }
        }
    }, [lastJsonMessage, setDashboard]);

    if (selected.length) {
        if (selectedExists) {
            if (dashboard) {
                return (
                    <div>
                        {dashboard.elements.map((el, i) =>
                            <HSVisualization
                                /* TODO: Support divStyle along with hs definition */
                                definition={JSON.parse(el.definition)}
                                key={i}
                            />
                        )}
                    </div>
                );
            } else {
                return <p>Loading {selected}...</p>;
            }
        } else {
            return <p>Dashboard was removed.</p>;
        }
    } else {
        return <p>No dashboard selected.</p>;
    }
}