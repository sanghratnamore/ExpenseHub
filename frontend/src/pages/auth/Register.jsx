import { useState } from "react";
import { registerUser } from "../../api/authApi";
import { useNavigate } from "react-router-dom";


function Register() {

  const navigate = useNavigate();


  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: ""
  });


  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");



  const handleChange = (e) => {

    setFormData({

      ...formData,

      [e.target.name]: e.target.value

    });

  };



  const handleSubmit = async (e) => {

    e.preventDefault();

    try {

      await registerUser(formData);


      setSuccess(
        "Registration successful. Redirecting to login..."
      );


      setTimeout(()=>{

        navigate("/login");

      },1500);


    } catch(error){

      console.log(error);


      setError(
        error.response?.data?.message ||
        "Registration failed"
      );

    }

  };



  return (

    <div className="min-h-screen flex items-center justify-center">


      <form
        onSubmit={handleSubmit}
        className="w-96 p-8 border rounded-xl shadow"
      >


        <h1 className="text-3xl font-bold text-blue-600 mb-6 text-center">
          Register
        </h1>



        {error && (

          <p className="text-red-500 mb-3">
            {error}
          </p>

        )}



        {success && (

          <p className="text-green-600 mb-3">
            {success}
          </p>

        )}



        <input

          name="name"

          placeholder="Name"

          className="w-full border p-3 rounded mb-4"

          onChange={handleChange}

        />



        <input

          name="email"

          type="email"

          placeholder="Email"

          className="w-full border p-3 rounded mb-4"

          onChange={handleChange}

        />



        <input

          name="password"

          type="password"

          placeholder="Password"

          className="w-full border p-3 rounded mb-4"

          onChange={handleChange}

        />



        <button

          className="w-full bg-blue-600 text-white py-3 rounded"

        >

          Create Account

        </button>


      </form>


    </div>

  );

}


export default Register;