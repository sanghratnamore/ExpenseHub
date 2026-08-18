import {
    PieChart,
    Pie,
    Cell,
    Tooltip,
    Legend
} from "recharts";


function CategoryChart({data}) {


    return (

        <div className="border rounded-xl p-5 shadow">

            <h2 className="text-xl font-bold mb-4">
                Expenses By Category
            </h2>


            <PieChart width={350} height={300}>

                <Pie
                    data={data}
                    dataKey="total"
                    nameKey="category"
                    cx="50%"
                    cy="50%"
                    outerRadius={100}
                    label
                >

                    {
                        data.map((entry,index)=>(

                            <Cell key={index}/>

                        ))
                    }

                </Pie>


                <Tooltip />

                <Legend />

            </PieChart>


        </div>

    );

}


export default CategoryChart;