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

// Отчеты
const getEmployeesReport = () => {
    return axios.get(`${API_URL}/reports/employees`, { headers: getHeaders() });
};

const getUniqueSkillsReport = () => {
    return axios.get(`${API_URL}/reports/unique-skills`, { headers: getHeaders() });
};

const getEmployeesWithoutPhoneReport = () => {
    return axios.get(`${API_URL}/reports/employees-without-phone`, { headers: getHeaders() });
};

// Уведомления и роли
const notifyInactiveEmployees = (norm) => {
    return axios.post(`${API_URL}/reports/notify-inactive`, { norm }, { headers: getHeaders() });
};

const assignRoleToEmployees = (norm, role) => {
    return axios.post(`${API_URL}/reports/assign-role`, { norm, role }, { headers: getHeaders() });
};

const notifyLowSkillLevels = (norm) => {
    return axios.post(`${API_URL}/reports/notify-low-skills`, { norm }, { headers: getHeaders() });
};

// Чаты
const getChats = () => {
    return axios.get(`${API_URL}/chats`, { headers: getHeaders() });
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

//Профиль
const getProfile = (id) => {
    return axios.get(`${API_URL}/profile/${id}`, { headers: getHeaders() });
};

// Офисы
const getOffices = () => {
    return axios.get(`${API_URL}/offices`, { headers: getHeaders() });
};

// Бизнес-центры
const getBusinessCenters = () => {
    return axios.get(`${API_URL}/business_centers`, { headers: getHeaders() });
};

// Отделы
const getDepartments = () => {
    return axios.get(`${API_URL}/departments`, { headers: getHeaders() });
};

// Должности
const getPositions = () => {
    return axios.get(`${API_URL}/positions`, { headers: getHeaders() });
};

const checkEmployeeActivity = () => {
    return axios.post(`${API_URL}/check_employee_activity`, {}, { headers: getHeaders() });
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

const getDocumentTemplate = () => {
    return axios.get(`${API_URL}/document_template`, { headers: getHeaders() });
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

// Личные сообщения
const sendPersonalMessage = (id_requester, content) => {
    return axios.post(`${API_URL}/messages`, { id_requester, content }, { headers: getHeaders() });
};

const getPersonalMessages = (userId) => {
    return axios.get(`${API_URL}/messages/${userId}`, { headers: getHeaders() });
};

const markPersonalMessageAsRead = (messageId) => {
    return axios.post(`${API_URL}/messages/${messageId}/read`, {}, { headers: getHeaders() });
};

// Получение событий на текущий день
const getTodaysEvents = () => {
    return axios.get(`${API_URL}/events/today`, { headers: getHeaders() });
};

// Объявления


const createAnnouncement = (data) => {
    return axios.post(`${API_URL}/announcements`, data, { headers: getHeaders() });
};

const updateAnnouncement = (id, data) => {
    return axios.put(`${API_URL}/announcements/${id}`, data, { headers: getHeaders() });
};

const deleteAnnouncement = (id) => {
    return axios.delete(`${API_URL}/announcements/${id}`, { headers: getHeaders() });
};

// Чаты
const addEmployeesToChat = (chatId, employeeIds) => {
    return axios.post(`/api/chats/${chatId}/add-employees`, { employeeIds }, { headers: getHeaders() });
};


export default {
    getChats,
    getMessages,
    sendMessage,
    markMessageAsRead,
    getTodaysEvents,            // Новый метод
    
    createAnnouncement,
    updateAnnouncement,
    deleteAnnouncement,
    addEmployeesToChat,
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
    sendPersonalMessage,
    getPersonalMessages,
    markPersonalMessageAsRead,
    getCardTypes,
    getDocuments,
    deleteDocument,
    
    getBusinessCards,
    createBusinessCard,
    updateBusinessCard,
    deleteBusinessCard,
    getOffices,
    getBusinessCenters,
    getDepartments,
    getPositions,
    
    createEvent, 
    updateEvent, 
    deleteEvent,
    getEventLocations,
    getDocumentTemplate,

    // Новые методы для отчетов
    getEmployeesReport,
    getUniqueSkillsReport,
    getEmployeesWithoutPhoneReport,
    notifyInactiveEmployees,
    assignRoleToEmployees,
    notifyLowSkillLevels,
};