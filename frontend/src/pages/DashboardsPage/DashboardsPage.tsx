import React, { useState } from 'react';

import './DashboardsPage.css'

import Dashboard from '../../components/Dashboard';
import DashboardTabs from '../../components/DashboardsTabs';

export default function DashboardsPage() {
    const [selected, setSelected] = useState<string>("");
    const [selectedExists, setSelectedExists] = useState<boolean>(false);

    return (
        <>
            <DashboardTabs selected={selected} setSelected={setSelected} setSelectedExists={setSelectedExists} />
            <Dashboard selected={selected} selectedExists={selectedExists} />
        </>
    );
}