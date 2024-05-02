import React from 'react';

import './GenerationRequestsPage.css'

export default function GenerationRequestsPage() {
    return (
        <>
            <h3>Send generation request:</h3>
            <p>Name: <input /></p>
            <input type="submit" value="Send" />
        </>
    );
}