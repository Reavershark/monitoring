import React, { useCallback, useEffect, useState } from 'react';
import useWebSocket from 'react-use-websocket';

import { webSocketUrl } from '../../config';

import './DashboardTabs.css';

const webSocketRequesters = {
    list: "DashboardTabs.list",
    subscribe: "DashboardTabs.subscribe",
};

interface Props {
    selected: string;
    setSelected: React.Dispatch<React.SetStateAction<string>>;
    setSelectedExists: React.Dispatch<React.SetStateAction<boolean>>;
}

export default function DashboardTabs({ selected, setSelected, setSelectedExists }: Props) {
    const [dashboardUris, setDashboardUris] = useState<Array<string>>([]);
    const { lastJsonMessage, sendJsonMessage } = useWebSocket(webSocketUrl, {
        share: true,
        shouldReconnect: () => true,
        filter: (message) => Object.values(webSocketRequesters).includes(JSON.parse(message.data).requester),
        onOpen() {
            sendSubscribe();
        },
    });

    const sendSubscribe = useCallback(() => {
        sendJsonMessage({
            "type": "subscribe",
            "path": [
                { "name": "dashboardManager" },
                { "name": "dashboardsChanged" },
            ],
            "requester": webSocketRequesters.subscribe,
        });
    }, [sendJsonMessage]);

    const sendList = useCallback(() => {
        sendJsonMessage({
            "type": "query",
            "path": [
                { "name": "dashboardManager" },
                { "name": "listDashboards" },
            ],
            "requester": webSocketRequesters.list,
        });
    }, [sendJsonMessage]);

    useEffect(() => {
        const msg: any = lastJsonMessage;
        if (!msg) {
            return;
        } else if (msg.error) { // Handle an error
            console.warn("Backend returned error: ", msg);
        } else if (msg.requester) { // Handle a response
            switch (msg.requester) {
                case webSocketRequesters.subscribe:
                    // Subscribed, fetch list once
                    sendList();
                    break;
                case webSocketRequesters.list:
                    setDashboardUris(msg.result);
                    break;
                default:
                    console.warn("Unknown requester: ", msg.requester);
                    break;
            }
        } else if (msg.event) { // Handle an event
            switch (msg.event) {
                case "dashboardsChanged":
                    setDashboardUris(msg.eventData);
                    break;
                default:
                    console.warn("Unknown event: ", msg.event);
            }
        }
    }, [lastJsonMessage, sendList, setDashboardUris])

    useEffect(() => {
        if (dashboardUris.length && !selected.length) {
            setSelected(dashboardUris[0]);
        }
        setSelectedExists(Object.values(dashboardUris).includes(selected));
    }, [dashboardUris, selected, setSelected, setSelectedExists, sendList]);

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
