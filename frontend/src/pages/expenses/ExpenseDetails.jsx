import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { deleteExpense, getExpense } from "../../api/expenseApi";

function ExpenseDetails() {

    const { id } = useParams();
    const navigate = useNavigate();

    const [expense, setExpense] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");
    const [deleting, setDeleting] = useState(false);

    useEffect(() => {

        const fetchExpense = async () => {

            try {

                setLoading(true);
                setError("");

                const data = await getExpense(id);

                setExpense(data);

            } catch (error) {

                console.log("Get expense error:", error);

                setError("Failed to load expense details");

            } finally {

                setLoading(false);

            }

        };

        fetchExpense();

    }, [id]);

    const handleDelete = async () => {

        const confirmed = window.confirm(
            "Are you sure you want to delete this expense?"
        );

        if (!confirmed) {
            return;
        }

        try {

            setDeleting(true);

            await deleteExpense(id);

            navigate("/expenses");

        } catch (error) {

            console.log("Delete expense error:", error);

            setError("Failed to delete expense");
            setDeleting(false);

        }

    };

    const formatDate = (date) => {

        if (!date) {
            return "Not available";
        }

        return new Date(date).toLocaleString();

    };

    if (loading) {

        return (

            <div className="min-h-screen bg-gray-50 p-10">

                <p className="text-center text-gray-500 py-12">
                    Loading expense details...
                </p>

            </div>

        );

    }

    if (!expense) {

        return (

            <div className="min-h-screen bg-gray-50 p-10">

                <div className="max-w-2xl mx-auto">

                    <div className="border border-red-200 bg-red-50 text-red-600 p-4 rounded-lg mb-6">
                        {error || "Expense not found"}
                    </div>

                    <button
                        type="button"
                        onClick={() => navigate("/expenses")}
                        className="border px-5 py-3 rounded-lg hover:bg-gray-100 transition"
                    >
                        Back to Expenses
                    </button>

                </div>

            </div>

        );

    }

    return (

        <div className="min-h-screen bg-gray-50 p-10">

            <div className="max-w-2xl mx-auto">

                <div className="flex flex-wrap items-center justify-between gap-4 mb-8">

                    <h1 className="text-4xl font-bold text-blue-600">
                        Expense Details
                    </h1>

                    <button
                        type="button"
                        onClick={() => navigate("/expenses")}
                        className="border px-5 py-3 rounded-lg hover:bg-gray-100 transition"
                    >
                        Back to Expenses
                    </button>

                </div>

                <div className="bg-white border rounded-xl p-8 shadow-sm">

                    {error && (

                        <div className="border border-red-200 bg-red-50 text-red-600 p-4 rounded-lg mb-6">
                            {error}
                        </div>

                    )}

                    <p className="text-gray-500 text-sm mb-1">
                        Description
                    </p>

                    <h2 className="text-2xl font-bold mb-6">
                        {expense.description}
                    </h2>

                    <div className="grid gap-6 sm:grid-cols-2">

                        <div>

                            <p className="text-gray-500 text-sm mb-1">
                                Amount
                            </p>

                            <p className="text-2xl font-bold text-blue-600">
                                ₹ {Number(expense.amount).toFixed(2)}
                            </p>

                        </div>

                        <div>

                            <p className="text-gray-500 text-sm mb-2">
                                Category
                            </p>

                            <span className="inline-block bg-blue-100 text-blue-700 px-3 py-1 rounded-full text-sm">
                                {expense.category}
                            </span>

                        </div>

                        <div>

                            <p className="text-gray-500 text-sm mb-1">
                                Expense Date
                            </p>

                            <p>{formatDate(expense.expenseDate)}</p>

                        </div>

                        <div>

                            <p className="text-gray-500 text-sm mb-1">
                                Created
                            </p>

                            <p>{formatDate(expense.createdAt)}</p>

                        </div>

                    </div>

                    {expense.user && (

                        <div className="border-t mt-6 pt-6">

                            <p className="text-gray-500 text-sm mb-1">
                                Created By
                            </p>

                            <p>
                                {expense.user.name || expense.user.email || "Not available"}
                            </p>

                        </div>

                    )}

                    <div className="flex flex-wrap gap-3 mt-8">

                        <button
                            type="button"
                            onClick={() => navigate(`/expenses/edit/${id}`)}
                            className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-3 rounded-lg transition"
                        >
                            Edit Expense
                        </button>

                        <button
                            type="button"
                            onClick={handleDelete}
                            disabled={deleting}
                            className="bg-red-500 hover:bg-red-600 text-white px-5 py-3 rounded-lg transition disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {deleting ? "Deleting..." : "Delete Expense"}
                        </button>

                    </div>

                </div>

            </div>

        </div>

    );

}

export default ExpenseDetails;
