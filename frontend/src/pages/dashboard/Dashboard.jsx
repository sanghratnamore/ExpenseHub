import { useEffect, useState } from "react";
import useAuthStore from "../../store/authStore";
import { useNavigate } from "react-router-dom";
import {
    getDashboardSummary,
    getCategoryExpenses,
    getMonthlyExpenses
} from "../../api/dashboardApi";

import CategoryChart from "../../components/charts/CategoryChart";
import MonthlyChart from "../../components/charts/MonthlyChart";

function Dashboard() {


    const [summary, setSummary] = useState(null);
    const [categories, setCategories] = useState([]);
    const [monthly, setMonthly] = useState([]);
    const [error, setError] = useState("");

    const logout = useAuthStore(
        (state) => state.logout
    );

    const navigate = useNavigate();



    useEffect(() => {

        const fetchDashboard = async () => {

            try {

                const summaryData =
                    await getDashboardSummary();


                const categoryData =
                    await getCategoryExpenses();


                const monthlyData =
                    await getMonthlyExpenses();



                setSummary(summaryData);

                setCategories(categoryData);

                setMonthly(monthlyData);


            } catch (err) {

                console.log(err);

                setError("Failed to load dashboard");

            }

        };


        fetchDashboard();


    }, []);




    if (error) {

        return (

            <h1 className="text-red-500 text-center mt-10">

                {error}

            </h1>

        );

    }




    if (!summary) {

        return (

            <h1 className="text-center mt-10">

                Loading...

            </h1>

        );

    }




    return (

        <div className="min-h-screen p-10">


            <div className="flex justify-between items-center mb-8">

                <h1 className="text-4xl font-bold text-blue-600">
                    ExpenseHub Dashboard
                </h1>


                <button
                    onClick={() => {
                        logout();
                        navigate("/login");
                    }}
                    className="bg-red-500 text-white px-5 py-2 rounded-lg"
                >
                    Logout
                </button>

            </div>



            <div className="grid grid-cols-4 gap-5">


                <div className="border rounded-xl p-5 shadow">

                    <h2>Total Expenses</h2>

                    <p className="text-2xl font-bold">

                        ₹ {summary.totalExpenses}

                    </p>

                </div>



                <div className="border rounded-xl p-5 shadow">

                    <h2>Expense Count</h2>

                    <p className="text-2xl font-bold">

                        {summary.expenseCount}

                    </p>

                </div>



                <div className="border rounded-xl p-5 shadow">

                    <h2>This Month</h2>

                    <p className="text-2xl font-bold">

                        ₹ {summary.thisMonth}

                    </p>

                </div>



                <div className="border rounded-xl p-5 shadow">

                    <h2>Today</h2>

                    <p className="text-2xl font-bold">

                        ₹ {summary.today}

                    </p>

                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mt-10">

                    <CategoryChart data={categories} />

                    <MonthlyChart data={monthly} />

                </div>


            </div>


        </div>

    );

}


export default Dashboard;