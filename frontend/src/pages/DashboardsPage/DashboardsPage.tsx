import React, { useState } from 'react';

import './DashboardsPage.css'

import Dashboard from '../../components/Dashboard';
import DashboardTabs from '../../components/DashboardsTabs';

export default function DashboardsPage() {
    const [selected, setSelected] = useState<string>("");

    return (
        <>
            <DashboardTabs selected={selected} setSelected={setSelected} />
            <Dashboard id={selected} />
        </>
    );
}