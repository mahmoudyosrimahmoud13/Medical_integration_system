import React from "react";
import { Chart } from "react-google-charts";

const dataLine = [
    ['Day', 'Patients'],
    ['Mon', 10],
    ['Tue', 25],
    ['Wed', 15],
    ['Thu', 40],
    ['Fri', 80],
    ['Sat', 35],
    ['San', 30],
];
const optionsLine = {
    title: 'Patients',
    curveType: 'function',
    legend: { position: 'bottom' },
    colors: ['#87CEEB'],
};

const dataPie = [
    ['Gender', 'Population'],
    ['Men', 45],
    ['Women', 55],
];

const optionsPie = {
    title: 'Gender',
    pieHole: .4,
    colors: ['#143F6B', '#FF69B4'],
};


const Charts = () => {
    return (
        <>
            <div className='chart'>
                <Chart chartType="LineChart" width="100%" height="200px" data={dataLine} options={optionsLine} 
                loader={<div>Loading Chart...</div>}/>
            </div>
            <div className='chart'>
                <Chart chartType="PieChart" width="100%" height="200px" data={dataPie} options={optionsPie}
                loader={<div>Loading Chart...</div>}/>
            </div>
        </>
    );
}
export default Charts;