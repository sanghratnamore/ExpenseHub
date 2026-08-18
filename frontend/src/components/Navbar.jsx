import { Link } from "react-router-dom";

function Navbar() {
  return (
    <nav className="w-full px-8 py-4 flex justify-between items-center border-b">

      <h1 className="text-2xl font-bold text-blue-600">
        ExpenseHub
      </h1>


      <div className="flex gap-6">

        <Link to="/">
          Home
        </Link>

        <Link to="/login">
          Login
        </Link>

        <Link to="/register">
          Register
        </Link>

      </div>

    </nav>
  );
}

export default Navbar;