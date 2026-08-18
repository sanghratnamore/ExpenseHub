import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
    getExpense,
    updateExpense
} from "../../api/expenseApi";


function EditExpense() {

    const { id } = useParams();
    const navigate = useNavigate();

    console.log("Editing expense ID:", id);

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
    useEffect(() => {

        const fetchExpense = async () => {

            try {

                const data = await getExpense(id);

                console.log("Expense loaded:", data);

                setFormData({
                    description: data.description,
                    amount: data.amount,
                    category: data.category,
                    expenseDate: data.expenseDate
                });

            } catch (error) {

                console.log("Get expense error:", error);

            }

        };

        fetchExpense();

    }, [id]);

    const handleSubmit = async (e) => {

        e.preventDefault();

        try {

            const data = {
                description: formData.description,
                amount: Number(formData.amount),
                category: formData.category,
                expenseDate: formData.expenseDate
            };

            const response = await updateExpense(id, data);

            console.log("Expense updated:", response);

            alert("Expense updated successfully!");
            navigate("/expenses");

        } catch (error) {

            console.log("Update expense error:", error);

            alert("Failed to update expense");

        }

    };

    return (

        <div className="min-h-screen bg-gray-50 p-10">

            <h1 className="text-4xl font-bold text-blue-600 mb-8">
                Edit Expense
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


                <input
                    name="category"
                    placeholder="Category"
                    className="w-full border p-3 rounded"
                    value={formData.category}
                    onChange={handleChange}
                    required
                />


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
                    Update Expense
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

export default EditExpense;