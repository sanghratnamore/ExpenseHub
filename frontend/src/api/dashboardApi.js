import api from "./axios";


export const getDashboardSummary = async () => {

    const response = await api.get(
        "/dashboard/summary"
    );

    return response.data;

};


export const getCategoryExpenses = async () => {

    const response = await api.get(
        "/dashboard/categories"
    );

    return response.data;

};


export const getMonthlyExpenses = async () => {

    const response = await api.get(
        "/dashboard/monthly"
    );

    return response.data;

};