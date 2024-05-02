import React, { useState, useEffect } from 'react';
import useWebSocket from 'react-use-websocket';

import './Dashboard.css'

import HSVisualization from '../HSVisualization';

import { webSocketUrl } from '../../config';

const webSocketRequesters = {
    general: "Dashboard"
};

interface Props {
    id: string;
}

interface JSONDashboard {
    id: string;
    data_sources: Array<DataSource>;
    elements: Array<DashboardElement>;
}

interface DataSource {
    uri: string;
}

interface DashboardElement {
    definition: Highcharts.Options;
}

export default function Dashboard({ id }: Props) {
    const [dashboard, setDashboard] = useState<JSONDashboard | null>();
    const { lastJsonMessage, sendJsonMessage } = useWebSocket(webSocketUrl, {
        shouldReconnect: () => true,
        share: true,
        filter: (message) => Object.values(webSocketRequesters).includes(JSON.parse(message.data).requester),
    });

    console.log(`Dashboard render: id = "${id}", dashboard = ${dashboard}`);

    useEffect(() => {
        if (id.length > 0) {
            sendJsonMessage({
                requester: webSocketRequesters.general,
                type: "query",
                path: [
                    { name: "dashboardManager" },
                    { name: "getDashboard", args: [id] },
                ]
            });
        }
    }, [id]);

    useEffect(() => {
        const msg: any = lastJsonMessage
        if (msg && msg.result)
        {
            console.log(`Received dashboard desc ${JSON.stringify(msg)}`);
            setDashboard(null);
        }
    }, [lastJsonMessage]);

    if (!dashboard) {
        return <p>Loading {id}...</p>
    }
    else {
        let i = 0;
        return (
            <div>
                {dashboard.elements.map(el =>
                    <HSVisualization
                        definition={el.definition}
                        key={i++}
                    />
                )}
            </div>
        );
    }
}