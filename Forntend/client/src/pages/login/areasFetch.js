
const Areas = (props) => {
    const areas = props.areas;
    return (
        // <select id="area" name="area" className="selectArea" defaultValue="" required>
        //     <option value="" disabled>Select a Area</option>
        <>
            {areas.map(area => (
                <option key={area.id} value={area.key}>
                    {area.key}
                </option>
            ))}
        </>
        // </select>
    );
}

export default Areas;
