import axios from 'axios';
import authService from './authService';

const API_URL = 'http://localhost:5000/api';

const getHeaders = () => {
    const user = authService.getCurrentUser();
    if (user && user.token) {
        return {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${user.token}`,
        };
    }
    return { 'Content-Type': 'application/json' };
};

// Чаты
const getChats = (userId) => {
    return axios.get(`${API_URL}/chats/${userId}`, { headers: getHeaders() });
};

const getMessages = (id_group_chat) => {
    return axios.get(`${API_URL}/chats/${id_group_chat}/messages`, { headers: getHeaders() });
};

const sendMessage = (id_group_chat, message) => {
    return axios.post(`${API_URL}/chats/${id_group_chat}/messages`, { content: message }, { headers: getHeaders() });
};

const markMessageAsRead = (id_message) => {
    return axios.post(`${API_URL}/messages/${id_message}/read`, {}, { headers: getHeaders() });
};

// Документы
const getDocumentTemplates = () => {
    return axios.get(`${API_URL}/document_templates`, { headers: getHeaders() });
};

const createDocument = (data) => {
    return axios.post(`${API_URL}/documents`, data, { headers: getHeaders() });
};

// События
const getEvents = () => {
    return axios.get(`${API_URL}/events`, { headers: getHeaders() });
};

// Объявления
const getActiveAnnouncements = () => {
    return axios.get(`${API_URL}/announcements/active`, { headers: getHeaders() });
};

const getAllAnnouncements = () => {
    return axios.get(`${API_URL}/announcements/all`, { headers: getHeaders() });
};

// Уведомления
const getUnreadMessagesCount = () => {
    const user = authService.getCurrentUser();
    return axios.get(`${API_URL}/messages/unread-count`, { headers: getHeaders() });
};

// Профиль
const getProfile = (id) => {
    return axios.get(`${API_URL}/profile/${id}`, { headers: getHeaders() });
};

// Сотрудники (админ)
const getEmployees = () => {
    return axios.get(`${API_URL}/employees`, { headers: getHeaders() });
};

const addEmployee = (data) => {
    return axios.post(`${API_URL}/employees`, data, { headers: getHeaders() });
};

const updateEmployee = (id, data) => {
    return axios.put(`${API_URL}/employees/${id}`, data, { headers: getHeaders() });
};

const deleteEmployee = (id) => {
    return axios.delete(`${API_URL}/employees/${id}`, { headers: getHeaders() });
};
const checkEmployeeActivity = () => {
    return axios.post(`${API_URL}/check_employee_activity`, {}, { headers: getHeaders() });
};


export default {
    getChats,
    getMessages,
    sendMessage,
    markMessageAsRead,
    getDocumentTemplates,
    createDocument,
    getEvents,
    getActiveAnnouncements,
    getAllAnnouncements,
    getUnreadMessagesCount,
    getProfile,
    getEmployees,
    addEmployee,
    updateEmployee,
    deleteEmployee,
    checkEmployeeActivity,
    // Другие методы
};