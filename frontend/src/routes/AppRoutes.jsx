import { BrowserRouter, Routes, Route } from "react-router-dom";

import PublicLayout from "../layouts/PublicLayout";
import Home from "../pages/Home";
import Login from "../pages/auth/Login";
import Register from "../pages/auth/Register";
import Dashboard from "../pages/dashboard/Dashboard";
import ProtectedRoute from "../components/ProtectedRoute";
import Expenses from "../pages/expenses/Expenses";
import AddExpense from "../pages/expenses/AddExpense";
import EditExpense from "../pages/expenses/EditExpense";
import ExpenseDetails from "../pages/expenses/ExpenseDetails";


function AppRoutes() {

  return (

    <BrowserRouter>

      <Routes>


        <Route

          path="/"

          element={

            <PublicLayout>

              <Home />

            </PublicLayout>

          }

        />

        <Route
          path="/login"
          element={
            <PublicLayout>
              <Login />
            </PublicLayout>
          }
        />


        <Route
          path="/register"
          element={
            <PublicLayout>
              <Register />
            </PublicLayout>
          }
        />

        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <Dashboard />
            </ProtectedRoute>
          }
        />

        <Route

          path="/expenses"

          element={
            <Expenses />
          }

        />

        <Route
          path="/expenses/add"
          element={
            <AddExpense />
          }
        />

        <Route
          path="/expenses/edit/:id"
          element={<EditExpense />}
        />

        <Route
          path="/expenses/:id"
          element={<ExpenseDetails />}
        />


      </Routes>

    </BrowserRouter>

  );

}


export default AppRoutes;
