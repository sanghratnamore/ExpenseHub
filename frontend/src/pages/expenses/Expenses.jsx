import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
    getExpenses,
    deleteExpense
} from "../../api/expenseApi";

function Expenses() {

    const navigate = useNavigate();

    // =========================================================
    // STATE
    // =========================================================

    const [expenses, setExpenses] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");

    // =========================================================
    // FILTER STATE
    // =========================================================

    const [categoryFilter, setCategoryFilter] = useState("All");
    const [fromDate, setFromDate] = useState("");
    const [toDate, setToDate] = useState("");
    const [sortOrder, setSortOrder] = useState("newest");
    const [searchTerm, setSearchTerm] = useState("");

    // =========================================================
    // FETCH EXPENSES
    // =========================================================

    const fetchExpenses = async () => {

        try {

            setLoading(true);
            setError("");

            const data = await getExpenses();

            setExpenses(data);

        } catch (error) {

            console.log("Fetch expenses error:", error);

            setError("Failed to load expenses");

        } finally {

            setLoading(false);

        }

    };

    // Load expenses when page opens
    useEffect(() => {

        fetchExpenses();

    }, []);

    // =========================================================
    // FILTER EXPENSES
    // =========================================================

    const filteredExpenses = expenses.filter((expense) => {

        // Category filter
        const matchesCategory =
            categoryFilter === "All" ||
            expense.category === categoryFilter;

        // Search filter
        const matchesSearch =
            expense.description
                .toLowerCase()
                .includes(searchTerm.toLowerCase());

        // Expense date
        const expenseDate =
            new Date(expense.expenseDate);

        // From date
        const matchesFromDate =
            !fromDate ||
            expenseDate >=
            new Date(`${fromDate}T00:00:00`);

        // To date
        const matchesToDate =
            !toDate ||
            expenseDate <=
            new Date(`${toDate}T23:59:59`);

        return (
            matchesCategory &&
            matchesSearch &&
            matchesFromDate &&
            matchesToDate
        );

    });

    // =========================================================
    // SORT EXPENSES
    // =========================================================

    const sortedExpenses = [...filteredExpenses].sort(
        (a, b) => {

            const dateA =
                new Date(a.expenseDate);

            const dateB =
                new Date(b.expenseDate);

            if (sortOrder === "newest") {
                return dateB - dateA;
            }

            return dateA - dateB;

        }
    );

    // =========================================================
    // TOTAL AMOUNT
    // =========================================================

    const totalAmount = filteredExpenses.reduce(
        (total, expense) =>
            total + Number(expense.amount),
        0
    );

    // =========================================================
    // CLEAR FILTERS
    // =========================================================

    const clearFilters = () => {

        setCategoryFilter("All");
        setFromDate("");
        setToDate("");
        setSortOrder("newest");
        setSearchTerm("");

    };

    // =========================================================
    // DELETE EXPENSE
    // =========================================================

    const handleDelete = async (id) => {

        const confirmed = window.confirm(
            "Are you sure you want to delete this expense?"
        );

        if (!confirmed) {
            return;
        }

        try {

            await deleteExpense(id);

            // Remove deleted expense from the UI
            setExpenses((currentExpenses) =>
                currentExpenses.filter(
                    (expense) => expense.id !== id
                )
            );

        } catch (error) {

            console.log(
                "Delete expense error:",
                error
            );

            setError("Failed to delete expense");

        }

    };

    const handleCardKeyDown = (event, id) => {

        if (event.target !== event.currentTarget) {
            return;
        }

        if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            navigate(`/expenses/${id}`);
        }

    };

    // =========================================================
    // UI
    // =========================================================

    return (

        <div className="min-h-screen bg-gray-50 p-10">

            {/* =================================================
                HEADER
            ================================================= */}

            <div className="flex items-center justify-between mb-8">

                <h1 className="text-4xl font-bold text-blue-600">
                    Expenses
                </h1>

                <div className="flex gap-3">

                    {/* Refresh */}

                    <button
                        onClick={fetchExpenses}
                        disabled={loading}
                        className="
                            border
                            px-5
                            py-3
                            rounded-lg
                            hover:bg-gray-100
                            transition
                            disabled:opacity-50
                            disabled:cursor-not-allowed
                        "
                    >
                        {loading
                            ? "Refreshing..."
                            : "Refresh"
                        }
                    </button>

                    {/* Add Expense */}

                    <button
                        onClick={() =>
                            navigate("/expenses/add")
                        }
                        className="
                            bg-blue-600
                            hover:bg-blue-700
                            text-white
                            px-5
                            py-3
                            rounded-lg
                            transition
                        "
                    >
                        + Add Expense
                    </button>

                </div>

            </div>


            {/* =================================================
                SEARCH
            ================================================= */}

            <input
                type="text"
                placeholder="Search expenses..."
                value={searchTerm}
                onChange={(e) =>
                    setSearchTerm(e.target.value)
                }
                className="
                    w-full
                    border
                    p-3
                    rounded-lg
                    mb-4
                    bg-white
                "
            />


            {/* =================================================
                CATEGORY + SORT
            ================================================= */}

            <div className="flex flex-wrap gap-4 mb-4">

                <select
                    value={categoryFilter}
                    onChange={(e) =>
                        setCategoryFilter(e.target.value)
                    }
                    className="
                        border
                        p-3
                        rounded-lg
                        bg-white
                    "
                >

                    <option value="All">
                        All Categories
                    </option>

                    <option value="Food">
                        Food
                    </option>

                    <option value="Travel">
                        Travel
                    </option>

                    <option value="Shopping">
                        Shopping
                    </option>

                    <option value="Bills">
                        Bills
                    </option>

                    <option value="Entertainment">
                        Entertainment
                    </option>

                    <option value="Education">
                        Education
                    </option>

                    <option value="Health">
                        Health
                    </option>

                    <option value="Other">
                        Other
                    </option>

                </select>


                <select
                    value={sortOrder}
                    onChange={(e) =>
                        setSortOrder(e.target.value)
                    }
                    className="
                        border
                        p-3
                        rounded-lg
                        bg-white
                    "
                >

                    <option value="newest">
                        Newest First
                    </option>

                    <option value="oldest">
                        Oldest First
                    </option>

                </select>

            </div>


            {/* =================================================
                DATE FILTERS
            ================================================= */}

            <div className="
                flex
                flex-wrap
                items-end
                gap-4
                mb-6
            ">

                <div>

                    <label className="block text-sm mb-1">
                        From
                    </label>

                    <input
                        type="date"
                        value={fromDate}
                        onChange={(e) =>
                            setFromDate(e.target.value)
                        }
                        className="
                            border
                            p-3
                            rounded-lg
                            bg-white
                        "
                    />

                </div>


                <div>

                    <label className="block text-sm mb-1">
                        To
                    </label>

                    <input
                        type="date"
                        value={toDate}
                        onChange={(e) =>
                            setToDate(e.target.value)
                        }
                        className="
                            border
                            p-3
                            rounded-lg
                            bg-white
                        "
                    />

                </div>


                <button
                    type="button"
                    onClick={clearFilters}
                    className="
                        border
                        px-5
                        py-3
                        rounded-lg
                        hover:bg-gray-100
                        transition
                    "
                >
                    Clear Filters
                </button>

            </div>


            {/* =================================================
                SUMMARY
            ================================================= */}

            <div className="
                bg-white
                border
                rounded-xl
                p-5
                shadow-sm
                mb-8
            ">

                <p className="text-gray-500 text-sm">
                    Total Expenses
                </p>

                <p className="
                    text-2xl
                    font-bold
                    text-blue-600
                ">
                    ₹ {totalAmount.toFixed(2)}
                </p>

                <p className="
                    text-gray-500
                    text-sm
                    mt-1
                ">
                    {filteredExpenses.length}{" "}
                    {
                        filteredExpenses.length === 1
                            ? "expense"
                            : "expenses"
                    }
                </p>

            </div>


            {/* =================================================
                ERROR
            ================================================= */}

            {error && (

                <div className="
                    mb-6
                    border
                    border-red-200
                    bg-red-50
                    text-red-600
                    p-4
                    rounded-lg
                ">
                    {error}
                </div>

            )}


            {/* =================================================
                LOADING / EMPTY / EXPENSE LIST
            ================================================= */}

            {loading ? (

                // Loading state

                <div className="
                    text-center
                    py-12
                ">

                    <p className="text-gray-500">
                        Loading expenses...
                    </p>

                </div>

            ) : expenses.length === 0 ? (

                // No expenses in database

                <div className="
                    text-center
                    py-12
                ">

                    <p className="
                        text-gray-500
                        mb-4
                    ">
                        No expenses found
                    </p>

                    <button
                        onClick={() =>
                            navigate("/expenses/add")
                        }
                        className="
                            bg-blue-600
                            hover:bg-blue-700
                            text-white
                            px-5
                            py-3
                            rounded-lg
                            transition
                        "
                    >
                        + Add your first expense
                    </button>

                </div>

            ) : filteredExpenses.length === 0 ? (

                // Expenses exist, but filters found nothing

                <div className="
                    text-center
                    py-12
                ">

                    <p className="
                        text-gray-500
                        mb-4
                    ">
                        No expenses match your filters.
                    </p>

                    <button
                        onClick={clearFilters}
                        className="
                            border
                            px-5
                            py-3
                            rounded-lg
                            hover:bg-gray-100
                            transition
                        "
                    >
                        Clear Filters
                    </button>

                </div>

            ) : (

                // Expense cards

                <div className="space-y-4">

                    {sortedExpenses.map((expense) => (

                        <div
                            key={expense.id}
                            role="button"
                            tabIndex={0}
                            onClick={() =>
                                navigate(`/expenses/${expense.id}`)
                            }
                            onKeyDown={(event) =>
                                handleCardKeyDown(event, expense.id)
                            }
                            className="
                                bg-white
                                border
                                rounded-xl
                                p-6
                                shadow-sm
                                hover:shadow-md
                                transition
                                cursor-pointer
                                focus:outline-none
                                focus:ring-2
                                focus:ring-blue-500
                                focus:ring-offset-2
                            "
                        >

                            {/* Description */}

                            <h2 className="
                                text-xl
                                font-bold
                            ">
                                {expense.description}
                            </h2>


                            {/* Amount */}

                            <p className="
                                text-lg
                                font-semibold
                                mt-2
                            ">
                                ₹{" "}
                                {Number(
                                    expense.amount
                                ).toFixed(2)}
                            </p>


                            {/* Category */}

                            <span className="
                                inline-block
                                mt-2
                                bg-blue-100
                                text-blue-700
                                px-3
                                py-1
                                rounded-full
                                text-sm
                            ">
                                {expense.category}
                            </span>


                            {/* Date */}

                            <p className="
                                text-gray-500
                                text-sm
                                mt-2
                            ">
                                {
                                    new Date(
                                        expense.expenseDate
                                    ).toLocaleString()
                                }
                            </p>


                            {/* Buttons */}

                            <div className="
                                flex
                                gap-2
                                mt-4
                            ">

                                {/* Delete */}

                                <button
                                    onClick={(event) => {
                                        event.stopPropagation();
                                        handleDelete(expense.id);
                                    }}
                                    className="
                                        bg-red-500
                                        hover:bg-red-600
                                        text-white
                                        px-4
                                        py-2
                                        rounded
                                        transition
                                    "
                                >
                                    Delete
                                </button>


                                {/* Edit */}

                                <button
                                    onClick={(event) => {
                                        event.stopPropagation();
                                        navigate(
                                            `/expenses/edit/${expense.id}`
                                        );
                                    }}
                                    className="
                                        bg-blue-600
                                        hover:bg-blue-700
                                        text-white
                                        px-4
                                        py-2
                                        rounded
                                        transition
                                    "
                                >
                                    Edit
                                </button>

                            </div>

                        </div>

                    ))}

                </div>

            )}

        </div>

    );

}

export default Expenses;
