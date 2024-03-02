import { useState, useEffect } from "react";

const FetchHook = (url) => {
    const [locations, setLocations] = useState([]);

    useEffect(() => {
        const fetchData = async () => {
            const ac = new AbortController();
            try {
                const res = await fetch(url, { signal: ac.signal });
                if (!res.ok) {
                    throw Error("Error");
                }
                const data = await res.json();
                setLocations(data);
            } catch (err) {
                if (err.name === "AbortError") {
                    console.log('AbortError');
                } else {

                }
            }
            return () => ac.abort();
        };

        fetchData();

    }, [url]);

    return (locations); // Return locations and error
};

export default FetchHook;
