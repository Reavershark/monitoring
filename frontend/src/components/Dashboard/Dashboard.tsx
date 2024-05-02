import React, { useState, useEffect } from 'react';
import useWebSocket from 'react-use-websocket';

import './Dashboard.css'

import HSVisualization from '../HSVisualization';

import { webSocketUrl } from '../../config';

const webSocketRequesters = {
    general: "Dashboard"
};

interface Props {
    uri: string;
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

export default function Dashboard({ uri }: Props) {
    const [dashboard, setDashboard] = useState<JsonDashboard | null>();
    const { lastJsonMessage, sendJsonMessage } = useWebSocket(webSocketUrl, {
        shouldReconnect: () => true,
        share: true,
        filter: (message) => Object.values(webSocketRequesters).includes(JSON.parse(message.data).requester),
    });

    console.log(`Dashboard render: uri = "${uri}", dashboard = ${dashboard}`);

    useEffect(() => {
        if (uri.length > 0) {
            sendJsonMessage({
                requester: webSocketRequesters.general,
                type: "query",
                path: [
                    { name: "dashboardManager" },
                    { name: "getDashboard", args: [uri] },
                ]
            });
        }
    }, [uri, sendJsonMessage]);

    useEffect(() => {
        const msg: any = lastJsonMessage
        if (msg && msg.result)
        {
            console.log(`Received dashboard desc ${JSON.stringify(msg)}`);
            setDashboard(msg.result);
        }
    }, [lastJsonMessage, setDashboard]);

    if (!dashboard) {
        return <p>Loading {uri}...</p>
    }
    else {
        let i = 0;
        return (
            <div>
                {dashboard.elements.map(el =>
                    <HSVisualization
                        /* TODO: Support divStyle along with hs definition */
                        definition={JSON.parse(el.definition)}
                        key={i++}
                    />
                )}
            </div>
        );
    }
}