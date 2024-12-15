import axios from 'axios';

const API_URL = 'http://localhost:5000/api';

const register = (data) => {
    return axios.post(`${API_URL}/register`, data);
};

const login = async ({ email, password }) => {
    const response = await axios.post(`${API_URL}/login`, { email, password }, {
        headers: {
            'Content-Type': 'application/json',
        },
    });
    // Предполагаем, что сервер возвращает { token, user }
    if (response.data.token) {
        localStorage.setItem('user', JSON.stringify(response.data));
    }
    console.log(response.data);
    return response.data;
};

const logout = () => {
    localStorage.removeItem('user');
};

const getCurrentUser = () => {
    return JSON.parse(localStorage.getItem('user'));
};

export default {
    register,
    login,
    logout,
    getCurrentUser,
};