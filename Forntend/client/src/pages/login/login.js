import SignIn from "./signIn";
import Register from "./register";

const Login = () => {
    // const areas = FetchHook(`http://localhost:5225/Adress/GetAreas`);
    return (
        <section className="login">
            <div className="container">
                <SignIn />
                <Register />
            </div>
        </section>
    );
}
export default Login;