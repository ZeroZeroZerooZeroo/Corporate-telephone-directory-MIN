import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import authService from '../services/authService';

function Navbar() {
    const [userData, setUserData] = useState(authService.getCurrentUser());
    const [user, setUser] = useState(userData ? userData.user : null);
    const location = useLocation();

    useEffect(() => {
        const updatedUserData = authService.getCurrentUser();
        setUserData(updatedUserData);
        setUser(updatedUserData ? updatedUserData.user : null);
    }, [location]);

    const handleLogout = () => {
        authService.logout();
        setUserData(null);
        setUser(null);
    };

    return (
        <nav style={styles.navbar}>
            <Link to="/" style={styles.link}>Главная</Link>
            {user && userData && userData.token ? (
                <>
                    <Link to="/profile" style={styles.link}>Профиль</Link>
                    <Link to="/documents" style={styles.link}>Документы</Link>
                    <Link to="/business-cards" style={styles.link}>Визитки</Link>
                    <Link to="/chats" style={styles.link}>Чаты</Link>
                    <Link to="/personal-messages" style={styles.link}>Личные Сообщения</Link>
                    <Link to="/events" style={styles.link}>События</Link>
                    <Link to="/announcements" style={styles.link}>Объявления</Link>
                    <Link to="/company-info" style={styles.link}>Информация о компании</Link>
                    {user.is_admin && (
                        <>
                            <Link to="/admin" style={styles.link}>Админ</Link>{/* Добавляем ссылки на новые отчеты */}
                            
                            
                  
                        </>
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