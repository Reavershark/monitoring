import React, { useState } from 'react';

import './ExampleComponent.css'

interface Props {
    message: String;
}

export default function ExampleComponent({ message }: Props) {
    const [checkboxState, setCheckboxState] = useState(false);

    return (
        <>
            <label>
                Toggle message:
                <input
                    type="checkbox"
                    checked={checkboxState}
                    onChange={e => setCheckboxState(e.target.checked)}
                />
            </label>
            {checkboxState && <p>{message}</p>}
        </>
    );
}