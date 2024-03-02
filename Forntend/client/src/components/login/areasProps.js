
const AreasProps = (props) => {
    const areas = props.areas;
    return (
        <>
            {areas.map(area => (
                <option key={area.id}>{area.key}</option>
            ))}
        </>
    );
}

export default AreasProps;
