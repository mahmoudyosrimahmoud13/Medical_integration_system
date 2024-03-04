import image from '../../photos/Health_professional_team_Customizable_Isometric_Illustrations___Amico_Style-removebg-preview.png';
const BeDoctor = () => {
    return(
        <div className="bedoc">
            <div className="form">
                <div className='img'>
                    <img src={image} alt="" />
                </div>
                <div className='forminfo'>
                    <h1>sir, you can join our team now.</h1>
                    <form>
                    <label className='cat'>address</label>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>area clinic</label>
                                <select>
                                    <option>1</option>
                                    <option>2</option>
                                    <option>3</option>
                                </select>
                            </div>
                            <div className='forminput'>
                                <label>address descrption</label>
                                <input type='text' />
                            </div>
                        </div>
                        <label className='cat'>information</label>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>college name</label>
                                <input type='text' />
                            </div>
                            <div className='forminput'>
                                <label>graduation year</label>
                                <input type='number' />
                            </div>
                        </div>
                        <div className='formrow'>
                            <div className='forminput'>
                                <label>specialization</label>
                                <select>
                                    <option>1</option>
                                    <option>2</option>
                                    <option>3</option>
                                </select>
                            </div>
                            <div className='forminput'>
                                <label>career summary</label>
                                <textarea />
                            </div>
                        </div>
                        <button className='apply'>apply</button>
                    </form>
                </div>
            </div>
        </div>
    )
}
export default BeDoctor;