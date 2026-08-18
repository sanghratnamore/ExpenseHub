import { useState } from "react";
import { loginUser } from "../../api/authApi";
import { useNavigate } from "react-router-dom";
import useAuthStore from "../../store/authStore";

function Login() {
    const navigate = useNavigate();

    const setToken = useAuthStore(
        (state) => state.setToken
    );

    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");

    const handleSubmit = async (e) => {

        e.preventDefault();

        try {

            const token = await loginUser({
                email,
                password
            });


            setToken(token);


            navigate("/dashboard");


        } catch (error) {

            console.log(error);

        }

    };

    return (

        <div className="min-h-screen flex items-center justify-center">

            <form
                onSubmit={handleSubmit}
                className="w-96 p-8 border rounded-xl shadow"
            >

                <h1 className="text-3xl font-bold text-blue-600 mb-6 text-center">
                    Login
                </h1>


                <input
                    type="email"
                    placeholder="Email"
                    className="w-full border p-3 rounded mb-4"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                />


                <input
                    type="password"
                    placeholder="Password"
                    className="w-full border p-3 rounded mb-4"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                />


                <button
                    className="w-full bg-blue-600 text-white py-3 rounded"
                >
                    Login
                </button>


            </form>

        </div>

    );

}

export default Login;