import React from 'react';
import * as Highcharts from 'highcharts';
import HighchartsMore from 'highcharts/highcharts-more';
import HighchartsReact from 'highcharts-react-official';

import './HSVisualization.css'

HighchartsMore(Highcharts);

interface Props {
    definition: Highcharts.Options
}

export default function HSVisualization({ definition }: Props) {
    if (!(definition.title && definition.title.text)) {
        definition.title = { text: "(No Title)" }
    }
    return (
        <div className='container'>
            <HighchartsReact
                highcharts={Highcharts}
                options={definition}
            />
        </div>
    );
}