import React from 'react';
import {
    Routes,
    Route,
    Navigate
} from "react-router-dom";

import './App.css';

import PageTabs from './components/PageTabs';

import DashboardsPage from './pages/DashboardsPage';
import GenerationRequestsPage from './pages/GenerationRequestsPage/GenerationRequestsPage';
import DocsPage from './pages/DocsPage';

export default function App() {
    return (
        <>
            <PageTabs />
            <Routes>
                <Route path="/" element={<DashboardsPage />} />
                <Route path="/requests" element={<GenerationRequestsPage />} />
                <Route path="/docs" element={<DocsPage />} />
                <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
        </>
    );
}
