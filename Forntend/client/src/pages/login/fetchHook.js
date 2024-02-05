import { useState, useEffect } from "react";


const FetchHook = (url) => {
    const [locations, setLocation] = useState(null);
    
    useEffect(() => {
            const fetchData = async () => {
                try{
                    const res = await fetch(url);
                    const data = await res.json();
                    setLocation(data);
                }
                catch(error) {
                    console.error('Error fetching data:', error);
                }
                
            }

            fetchData();
    }, [url]);
    return (locations);
}
export default FetchHook;