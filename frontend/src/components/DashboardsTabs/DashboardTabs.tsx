import React, { useEffect, useState } from 'react';
import useWebSocket from 'react-use-websocket';

import { webSocketUrl } from '../../config';

import './DashboardTabs.css';

const webSocketRequesters = {
    general: "DashboardTabs"
};

interface Props {
    selected: string;
    setSelected: React.Dispatch<React.SetStateAction<string>>;
}

export default function DashboardTabs({ selected, setSelected }: Props) {
    const [dashboardUris, setDashboardUris] = useState<Array<string>>([]);
    const { lastJsonMessage, sendJsonMessage } = useWebSocket(webSocketUrl, {
        onOpen() {
            sendJsonMessage({
                "requester": webSocketRequesters.general,
                "type": "query",
                "path": [
                    { "name": "dashboardManager" },
                    { "name": "listDashboards" },
                ]
            });
        },
        share: true,
        shouldReconnect: () => true,
        filter: (message) => Object.values(webSocketRequesters).includes(JSON.parse(message.data).requester),
    });

    useEffect(() => {
        const msg: any = lastJsonMessage
        if (msg && msg.result) {
            const ids: Array<string> = msg.result;
            setDashboardUris(ids);

            if (selected === "" && ids.length > 0) {
                setSelected(ids[0])
            }

            const interval = setTimeout(() => {
                sendJsonMessage({
                    requester: webSocketRequesters.general,
                    type: "query",
                    path: [
                        { name: "dashboardManager" },
                        { name: "listDashboards" },
                    ]
                });
            }, 1000);
            return () => clearInterval(interval);
        }
    }, [lastJsonMessage, sendJsonMessage, setDashboardUris, selected, setSelected])

    return (
        <div className="tabList">
            {dashboardUris.map(uri =>
                <div
                    className={"tab" + (selected === uri ? " tab-selected" : "")}
                    onClick={() => setSelected(uri)}
                    key={uri}
                >
                    {uri}
                </div>
            )}
        </div>
    );
}
