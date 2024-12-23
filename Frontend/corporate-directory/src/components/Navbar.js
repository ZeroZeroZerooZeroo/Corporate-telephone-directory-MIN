import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import authService from '../services/authService';
import apiService from '../services/apiService'; 

function Navbar() {
    const [userData, setUserData] = useState(authService.getCurrentUser());
    const user = userData ? userData.user : null;
    const location = useLocation();
    const [unreadCount, setUnreadCount] = useState(0);


    useEffect(() => {
        const updatedUserData = authService.getCurrentUser();
        setUserData(updatedUserData);
    }, [location]);

    const handleLogout = () => {
        authService.logout();
        setUserData(null);
        window.location.reload();
    };

    

    useEffect(() => {
        const fetchUnreadCount = async () => {
            try {
                const notifications = await apiService.getNotifications();
                const count = notifications.data.filter(n => !n.is_read).length;
                setUnreadCount(count);
            } catch (err) {
                console.error(err);
            }
        };
        fetchUnreadCount();

        const interval = setInterval(fetchUnreadCount, 60000); // Обновление каждые 60 секунд
        return () => clearInterval(interval);
    }, []);

    return (
        <nav style={styles.navbar}>
            
            {user && userData && userData.token ? (
                <>
                    <Link to="/profile" style={styles.link}>Профиль</Link>
                    <Link to="/documents" style={styles.link}>Документы</Link>
                    <Link to="/business-cards" style={styles.link}>Визитки</Link>
                    <Link to="/chats" style={styles.link}>Чаты</Link>
                    <Link to="/personal-messages" style={styles.link}>Личные Сообщения</Link>
                    <Link to="/events" style={styles.link}>События</Link>
                    <Link to="/notifications" style={styles.link}>
                        Уведомления 
                    </Link>
                    <Link to="/announcements" style={styles.link}>Объявления</Link>
                    <Link to="/positions" style={styles.link}>Данные компании</Link>
                    {user.is_admin && (
                        <Link to="/admin" style={styles.link}>Админ</Link>
                    )}
                    <button onClick={handleLogout} style={styles.logoutButton}>Выход</button>
                </>
            ) : (
                <>
                    <Link to="/login" style={styles.link}>Вход</Link>
                    <Link to="/register" style={styles.link}>Регистрация</Link>
                </>
            )}
        </nav>
    );
}

const styles = {
    navbar: {
        padding: '10px',
        borderBottom: '1px solid #ccc',
        marginBottom: '20px',
        display: 'flex',
        alignItems: 'center',
        flexWrap: 'wrap',
    },
    link: {
        marginRight: '15px',
        textDecoration: 'none',
        color: '#333',
        marginBottom: '5px',
    },
    logoutButton: {
        padding: '5px 10px',
        cursor: 'pointer',
        backgroundColor: '#f44336',
        color: '#fff',
        border: 'none',
        borderRadius: '3px',
    },
};

export default Navbar;