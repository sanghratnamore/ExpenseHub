import {
    LineChart,
    Line,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    Legend
} from "recharts";


function MonthlyChart({ data }) {


    return (

        <div className="border rounded-xl p-5 shadow mt-10">


            <h2 className="text-xl font-bold mb-4">
                Monthly Expenses
            </h2>


            <LineChart
                width={450}
                height={300}
                data={data}
            >

                <CartesianGrid strokeDasharray="3 3" />


                <XAxis
                    dataKey="month"
                />


                <YAxis />


                <Tooltip />


                <Legend />


                <Line
                    type="monotone"
                    dataKey="total"
                    stroke="#2563eb"
                    strokeWidth={3}
                />


            </LineChart>


        </div>

    );

}


export default MonthlyChart;