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

const deleteEmployee= (id) => {
    return axios.delete(`${API_URL}/employees/${id}`, { headers: getHeaders() });
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
const getUnreadMessagesCount = (userId) => {
    return axios.get(`${API_URL}/messages/unread-count`, { headers: getHeaders() });
};

// Профиль
const getProfile = (id) => {
    return axios.get(`${API_URL}/profile/${id}`,{ headers: getHeaders() });
};



const checkEmployeeActivity = () => {
    return axios.post(`${API_URL}/check_employee_activity, {}`, { headers: getHeaders() });
};



// Documents (CRUD)
const getDocuments = () => {
    return axios.get(`${API_URL}/documents`, { headers: getHeaders() });
};



const updateDocument = (id, data) => {
    return axios.put(`${API_URL}/documents/${id}`, data, { headers: getHeaders() });
};

const deleteDocument = (id) => {
    return axios.delete(`${API_URL}/documents/${id}`, { headers: getHeaders() });
};

// Business Cards (CRUD)
const getBusinessCards = () => {
    return axios.get(`${API_URL}/business_cards`, { headers: getHeaders() });
};

const createBusinessCard = (data) => {
    return axios.post(`${API_URL}/business_cards`, data, { headers: getHeaders() });
};

const updateBusinessCard = (id, data) => {
    return axios.put(`${API_URL}/business_cards/${id}`, data, { headers: getHeaders() });
};

const deleteBusinessCard = (id) => {
    return axios.delete(`${API_URL}/business_cards/${id}`, { headers: getHeaders() });
};

// Events (CRUD)

const getCardTypes = () => {
    return axios.get(`${API_URL}/card_types`, { headers: getHeaders() });
};


const createEvent = (data) => {
    return axios.post(`${API_URL}/events`, data, { headers: getHeaders() });
};

const updateEvent = (id, data) => {
    return axios.put(`${API_URL}/events/${id}`, data, { headers: getHeaders() });
};

const deleteEvent = (id) => {
    return axios.delete(`${API_URL}/events/${id}`, { headers: getHeaders() });
};

// Event Locations
const getEventLocations = () => {
    return axios.get(`${API_URL}/event_locations`, { headers: getHeaders() });
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
    updateDocument,
    checkEmployeeActivity,
    getCardTypes,
    getDocuments,
   deleteDocument,

     getBusinessCards ,
    createBusinessCard,
   updateBusinessCard,
    
    
    deleteBusinessCard ,
     createEvent, updateEvent, deleteEvent ,
     getEventLocations ,
    
    // Другие методы
};