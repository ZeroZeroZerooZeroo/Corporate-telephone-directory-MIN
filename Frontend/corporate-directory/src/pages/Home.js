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
                        apiService.getEvents(),
                        apiService.getActiveAnnouncements(),
                        apiService.getUnreadMessagesCount(user.id_employee)
                    ]);
    
                    setEvents(eventsResponse.data);
                    setAnnouncements(announcementsResponse.data);
                    setNotifications(notificationsResponse.data);
                }
            } catch (err) {
                console.error('Ошибка при загрузке данных на главной странице:', err);
                setError('Ошибка загрузки данных');
            }
        };
        fetchData();
    }, [user]);

    if (!user) return <p>Загрузка...</p>;

    return (
        <div>
            <h2>Добро пожаловать, {user.full_name}</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            <section>
                <h3>События</h3>
                <ul>
                    {events.map(event => (
                        <li key={event.id_event}>
                            <p><strong>{event.name}</strong> - {new Date(event.date).toLocaleDateString()}</p>
                            <p>{event.discription}</p>
                        </li>
                    ))}
                </ul>
            </section>
            <section>
                <h3>Объявления</h3>
                <ul>
                    {announcements.map(announcement => (
                        <li key={announcement.id_announcement}>
                            <p><strong>{announcement.title}</strong>: {announcement.discription}</p>
                            <p>С: {new Date(announcement.creation_date).toLocaleDateString()} По: {new Date(announcement.end_date).toLocaleDateString()}</p>
                        </li>
                    ))}
                </ul>
            </section>
            <section>
                <h3>Уведомления</h3>
                <ul>
                    {notifications.map(notification => (
                        <li key={notification.id_message}>
                            {notification.content}
                        </li>
                    ))}
                </ul>
            </section>
        </div>
    );
}

export default Home;