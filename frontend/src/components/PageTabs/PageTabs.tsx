import React  from 'react';
import { useNavigate } from 'react-router-dom';

import './PageTabs.css';

const pages = [
    { "path": "/", "name": "Dashboards" },
    { "path": "/requests", "name": "Generation requests" },
    { "path": "/editor", "name": "Visualization template editor" },
    { "path": "/docs", "name": "Swagger UI" }
];

export default function PageTabs() {
    const navigate = useNavigate();
    return (
        <div className="tabList">
            {pages.map(page =>
                <div
                    className={"tab" + (window.location.pathname === page.path ? " tab-selected" : "")}
                    onClick={() => navigate(page.path)}
                    key={page.name}
                >
                    {page.name}
                </div>
            )}
        </div>
    );
}