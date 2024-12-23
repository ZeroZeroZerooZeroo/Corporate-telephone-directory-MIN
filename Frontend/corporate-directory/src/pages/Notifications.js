import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';
import authService from '../services/authService';

function Notifications() {
    const [notifications, setNotifications] = useState([]);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(true);

    // Получаем текущего пользователя
    const userData = authService.getCurrentUser();
    const user = userData ? userData.user : null;

    const fetchNotifications = async () => {
        if (!user || !user.id_employee) {
            setError('Пользователь не авторизован');
            setLoading(false);
            return;
        }

        try {
            const response = await apiService.getNotifications();
            // Фильтруем уведомления по id_employee
            const userNotifications = response.data.filter(n => n.id_employee === user.id_employee);

            // Удаляем дублирующиеся уведомления по содержимому
            const uniqueNotifications = [];
            const seenContents = new Set();

            userNotifications.forEach(n => {
                if (!seenContents.has(n.content)) {
                    uniqueNotifications.push(n);
                    seenContents.add(n.content);
                }
            });

            setNotifications(uniqueNotifications);
        } catch (err) {
            console.error(err);
            setError('Ошибка получения уведомлений');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchNotifications();
    }, [user]); 

    const handleMarkAsRead = async (id) => {
        try {
            await apiService.markNotificationAsRead(id);
            setNotifications(notifications.map(n => 
                n.id_notification === id ? { ...n, is_read: true } : n
            ));
        } catch (err) {
            console.error(err);
            setError('Ошибка отметки уведомления как прочитанного');
        }
    };

    // Автообновление уведомлений каждые 60 секунд
    useEffect(() => {
        if (!user) return;

        const interval = setInterval(() => {
            fetchNotifications();
        }, 60000); 

        return () => clearInterval(interval);
    }, [user]); 

    return (
        <div>
            <h2>Уведомления</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {loading ? (
                <p>Загрузка...</p>
            ) : notifications.length > 0 ? (
                <ul>
                    {notifications.map(notification => (
                        <li 
                            key={notification.id_notification} 
                            style={{ 
                                marginBottom: '10px', 
                                backgroundColor: notification.is_read ? '#f0f0f0' : '#e6f7ff', 
                                padding: '10px', 
                                borderRadius: '5px' 
                            }}
                        >
                            <p>{notification.content}</p>
                            <p style={{ fontSize: '0.9em', color: '#555' }}>
                                Получено: {new Date(notification.created_at).toLocaleString()}
                            </p>
                            {!notification.is_read && (
                                <button 
                                    onClick={() => handleMarkAsRead(notification.id_notification)} 
                                    style={{ marginTop: '5px', padding: '5px 10px' }}
                                >
                                    Отметить как прочитанное
                                </button>
                            )}
                        </li>
                    ))}
                </ul>
            ) : (
                <p>Нет уведомлений</p>
            )}
        </div>
    );
}

export default Notifications;