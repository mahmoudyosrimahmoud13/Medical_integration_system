const ClinicAreasProps = (props) => {
    const areas = props.areas;
    return (
        <>
            {areas.map(area => (
                <option value={area.id} key={area.id}>{area.key}</option>
            ))}
        </>
    );
}

export default ClinicAreasProps;
