import SignIn from "./signIn";
import Register from "./register";

const Login = () => {
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