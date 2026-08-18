import hero from "../assets/hero.png";


function Home(){

  return (

    <section className="min-h-screen flex items-center justify-center px-10">

      <div className="text-center">

        <h1 className="text-5xl font-bold text-blue-600">
          Manage Money Together
        </h1>


        <p className="mt-4 text-gray-600 text-lg">
          Track expenses, split bills and settle payments effortlessly.
        </p>


        <img
          src={hero}
          className="w-96 mx-auto mt-10"
        />

      </div>

    </section>

  );
}

export default Home;