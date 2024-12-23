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



// События
const getEvents = () => {
    return axios.get(`${API_URL}/events`, { headers: getHeaders() });
};

// Объявления

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



const checkEmployeeActivity = () => {
    return axios.post(`${API_URL}/check_employee_activity`, {}, { headers: getHeaders() });
};


const getDocuments = () => {
    return axios.get(`${API_URL}/documents`, { headers: getHeaders() });
};



const deleteDocument = (id) => {
    return axios.delete(`${API_URL}/documents/${id}`, { headers: getHeaders() });
};

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

// Добавление сотрудников в чат



const addUserToChat = (id_group_chat, id_employee, id_role) => {
    return axios.post(`${API_URL}/chats/${id_group_chat}/add-user`, { id_employee, id_role }, { headers: getHeaders() });
};

const getRoles = () => {
    return axios.get(`${API_URL}/roles`, { headers: getHeaders() });
};


// методы для получения информации о компании
const getOffices = () => {
    return axios.get(`${API_URL}/offices`, { headers: getHeaders() });
};

const getBusinessCenters = () => {
    return axios.get(`${API_URL}/business_centers`, { headers: getHeaders() });
};

const getDepartments = () => {
    return axios.get(`${API_URL}/departments`, { headers: getHeaders() });
};

const getPositions = () => {
    return axios.get(`${API_URL}/positions`, { headers: getHeaders() });
};



// Получение событий на текущий день
const getTodaysEvents = () => {
    return axios.get(`${API_URL}/events/today`, { headers: getHeaders() });
};






// Уведомления
const getNotifications = () => {
    return axios.get(`${API_URL}/notifications`, { headers: getHeaders() });
};

const markNotificationAsRead = (id) => {
    return axios.put(`${API_URL}/notifications/${id}`, { is_read: true }, { headers: getHeaders() });
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

const notifyInactiveEmployees = (norm) => {
    return axios.post(`${API_URL}/reports/notify-inactive`, { norm }, { headers: getHeaders() });
};

const assignRoleToEmployees = (norm, roleName) => {
    return axios.post(`${API_URL}/reports/assign-role`, { norm, roleName }, { headers: getHeaders() });
};

const notifyLowSkillLevels = (norm) => {
    return axios.post(`${API_URL}/reports/notify-low-skills`, { norm }, { headers: getHeaders() });
};




// Методы для отчетов
const getCountUnreadMessagesPerEmployee = () => {
    return axios.get(`${API_URL}/reports/count-unread-messages`, { headers: getHeaders() });
};

const getListTodaysEvents = () => {
    return axios.get(`${API_URL}/reports/list-todays-events`, { headers: getHeaders() });
};

const isAnnouncementActive = (id) => {
    return axios.get(`${API_URL}/reports/is-announcement-active`, { headers: getHeaders() });
};


const createDocument = (data) => {
    return axios.post(`${API_URL}/documents`, data, { headers: getHeaders() });
};

const updateDocument = (id, data) => {
    return axios.put(`${API_URL}/documents/${id}`, data, { headers: getHeaders() });
};

const getActiveAnnouncements = () => {
    return axios.get(`${API_URL}/announcements/active`, { headers: getHeaders() });
};

// Получение всех должностей
const getJobTitles = () => {
    return axios.get(`${API_URL}/job_titles`, { headers: getHeaders() });
};



// Получение всех навыков
const getSkills = () => {
    return axios.get(`${API_URL}/skills`, { headers: getHeaders() });
};

// Получение всех уровней навыков
const getLevels = () => {
    return axios.get(`${API_URL}/levels`, { headers: getHeaders() });
};



export default {
    getChats,
    getJobTitles,
    
    
    getSkills,
    getLevels,
    getMessages,
    sendMessage,
    getCountUnreadMessagesPerEmployee,
    getListTodaysEvents,
    isAnnouncementActive,
    markMessageAsRead,
    getTodaysEvents,
    markNotificationAsRead,            
    getRoles,
    createAnnouncement,
    updateAnnouncement,
    deleteAnnouncement,
    addUserToChat,
    getNotifications,
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


    getEmployeesReport,
    getUniqueSkillsReport,
    getEmployeesWithoutPhoneReport,
    notifyInactiveEmployees,
    assignRoleToEmployees,
    notifyLowSkillLevels,
};