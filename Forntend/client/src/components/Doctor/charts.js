import React from "react";
import { Chart } from "react-google-charts";
import { useState, useEffect } from "react";

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






const Charts = () => {
    const userToken = localStorage.getItem('usertoken');
    const convertToken = JSON.parse(userToken);
    // const [data, setData] = useState('');
    const [dataPie, setData] = useState('');
    useEffect(() => {
        const fetchData = async () => {
        try {
            const apiUrl = 'http://localhost:5225/Hospital/Doctor/PatientPercentage';
            const response = await fetch(apiUrl, {
                method: "GET",
                headers: {
                    'Authorization': `Bearer ${convertToken.token}`
                },
            });
    
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
    
            const data = await response.json();
            if(data.length < 1){
                const dataPie = [
                    ['Gender', 'Population'],
                    ['Men', data],
                    ['Women', 100-data],
                ];
                setData(dataPie);
            }
            else if(data === 100){
                const dataPie = [
                    ['Gender', 'Population'],
                    ['Men', data],
                    ['Women', 100-data],
                ];
                setData(dataPie);
            }
            
            else{
                const dataPie = [
                    ['Gender', 'Population'],
                    ['Men', data],
                    ['Women', 100-data],
                ];
                setData(dataPie);
            }
    
            
        }
        catch (error) {
            console.log(error);
        }
        };
    
        fetchData();
    }, []);






    

    const optionsPie = {
        title: 'Gender',
        pieHole: .4,
        colors: ['#143F6B', '#FF69B4'],
    };
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