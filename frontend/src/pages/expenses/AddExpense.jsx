import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { createExpense } from "../../api/expenseApi";

function AddExpense() {

    const navigate = useNavigate();

    const [formData, setFormData] = useState({
        description: "",
        amount: "",
        category: "",
        expenseDate: ""
    });


    const handleChange = (e) => {

        setFormData({
            ...formData,
            [e.target.name]: e.target.value
        });

    };


    const handleSubmit = async (e) => {

        e.preventDefault();

        try {

            const data = {
                description: formData.description,
                amount: Number(formData.amount),
                category: formData.category,
                expenseDate: formData.expenseDate
            };

            const response = await createExpense(data);

            console.log("Expense created:", response);

            alert("Expense added successfully!");

        } catch (error) {

            console.log("Create expense error:", error);

            alert("Failed to add expense");

        }

    };



    return (

        <div className="min-h-screen p-10">

            <h1 className="text-4xl font-bold text-blue-600 mb-8">
                Add Expense
            </h1>

            <form
                onSubmit={handleSubmit}
                className="max-w-xl border rounded-xl p-8 shadow space-y-5"
            >

                <input
                    name="description"
                    placeholder="Description"
                    className="w-full border p-3 rounded"
                    value={formData.description}
                    onChange={handleChange}
                    required
                />

                <input
                    name="amount"
                    type="number"
                    step="0.01"
                    min="0.01"
                    placeholder="Amount"
                    className="w-full border p-3 rounded"
                    value={formData.amount}
                    onChange={handleChange}
                    required
                />

                <select
                    name="category"
                    className="w-full border p-3 rounded"
                    value={formData.category}
                    onChange={handleChange}
                    required
                >
                    <option value="">Select Category</option>
                    <option value="Food">Food</option>
                    <option value="Travel">Travel</option>
                    <option value="Shopping">Shopping</option>
                    <option value="Bills">Bills</option>
                    <option value="Entertainment">Entertainment</option>
                    <option value="Education">Education</option>
                    <option value="Health">Health</option>
                    <option value="Other">Other</option>
                </select>



                <input
                    name="expenseDate"
                    type="datetime-local"
                    className="w-full border p-3 rounded"
                    value={formData.expenseDate}
                    onChange={handleChange}
                    required
                />

                <button
                    type="submit"
                    className="w-full bg-blue-600 text-white py-3 rounded"
                >
                    Add Expense
                </button>

                <button
                    type="button"
                    onClick={() => navigate("/expenses")}
                    className="w-full border py-3 rounded"
                >
                    Cancel
                </button>

            </form>

        </div>

    );
}

export default AddExpense;