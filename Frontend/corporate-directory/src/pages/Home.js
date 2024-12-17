import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';
import authService from '../services/authService';

function Home() {
    const userData = authService.getCurrentUser();
    const user = userData ? userData.user : null;
    const [events, setEvents] = useState([]);
    const [announcements, setAnnouncements] = useState([]);
    const [notifications, setNotifications] = useState([]);
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchData = async () => {
            try {
                if (user) {
                    const [eventsResponse, announcementsResponse, notificationsResponse] = await Promise.all([
                        apiService.getTodaysEvents(),
                        apiService.getActiveAnnouncements(),
                        apiService.getNotifications(),
                    ]);

                    setEvents(eventsResponse.data);
                    setAnnouncements(announcementsResponse.data);
                    setNotifications(notificationsResponse.data);
                }
            } catch (err) {
                console.error(err);
                setError('Ошибка при загрузке данных');
            }
        };
        fetchData();
    }, [user]);

    const handleMarkAsRead = async (id) => {
        try {
            await apiService.markNotificationAsRead(id);
            setNotifications(notifications.map(n => n.id_notification === id ? { ...n, is_read: true } : n));
        } catch (err) {
            console.error(err);
            setError('Ошибка при отметке уведомления как прочитанного');
        }
    };

    if (!user) return <p>Загрузка...</p>;

    return (
        <div>
            <h2>Добро пожаловать, {user.full_name}</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            
            <section>
                <h3>Уведомления</h3>
                {notifications.length > 0 ? (
                    <ul>
                        {notifications.map(notification => (
                            <li key={notification.id_notification} style={{ marginBottom: '10px' }}>
                                <p>{notification.content}</p>
                                <p>Получено: {new Date(notification.created_at).toLocaleString()}</p>
                                {!notification.is_read && (
                                    <button onClick={() => handleMarkAsRead(notification.id_notification)} style={{ marginTop: '5px' }}>
                                        Отметить как прочитанное
                                    </button>
                                )}
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p>Нет новых уведомлений</p>
                )}
            </section>

            <section>
                <h3>События на сегодня</h3>
                {events.length > 0 ? (
                    <ul>
                        {events.map(event => (
                            <li key={event.id_event} style={{ marginBottom: '10px' }}>
                                <p><strong>{event.name}</strong> - {new Date(event.date).toLocaleDateString()}</p>
                                <p>{event.discription}</p>
                                <p>Создал: {event.creator_name}</p>
                                <p>Место: {event.event_location_name}</p>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p>Отсутствуют</p>
                )}
            </section>

            <section>
                <h3>Активные Объявления</h3>
                {announcements.length > 0 ? (
                    <ul>
                        {announcements.map(announcement => (
                            <li key={announcement.id_announcement} style={{ marginBottom: '10px' }}>
                                <h4>{announcement.title}</h4>
                                <p>{announcement.discription}</p>
                                <p>С: {new Date(announcement.creation_date).toLocaleDateString()} По: {new Date(announcement.end_date).toLocaleDateString()}</p>
                                <p>Создал: {announcement.id_employee}</p>
                            </li>
                        ))}
                    </ul>
                ) : (
                    <p>Нет активных объявлений</p>
                )}
            </section>
        </div>
    );
}

export default Home;