import React from 'react';
import { Link } from 'react-router-dom';
import authService from '../services/authService';

function Navbar() {
    const userData = authService.getCurrentUser();
    const user = userData ? userData.user : null;

    const handleLogout = () => {
        authService.logout();
        window.location.reload();
    };

    return (
        <nav style={{ padding: '10px', borderBottom: '1px solid #ccc', marginBottom: '20px' }}>
            <Link to="/" style={{ marginRight: '15px', textDecoration: 'none' }}>Главная</Link>
            {user && userData.token ? (
                <>
                    <Link to="/profile" style={{ marginRight: '15px', textDecoration: 'none' }}>Профиль</Link>
                    <Link to="/documents" style={{ marginRight: '15px', textDecoration: 'none' }}>Документы</Link>
                    <Link to="/business-cards" style={{ marginRight: '15px', textDecoration: 'none' }}>Визитки</Link>
                    <Link to="/chats" style={{ marginRight: '15px', textDecoration: 'none' }}>Чаты</Link>
                    <Link to="/events" style={{ marginRight: '15px', textDecoration: 'none' }}>События</Link>
                    <Link to="/announcements" style={{ marginRight: '15px', textDecoration: 'none' }}>Объявления</Link>
                    {user.is_admin && <Link to="/admin" style={{ marginRight: '15px', textDecoration: 'none' }}>Админ</Link>}
                    <button onClick={handleLogout} style={{ padding: '5px 10px', cursor: 'pointer' }}>Выход</button>
                </>
            ) : (
                <>
                    <Link to="/login" style={{ marginRight: '15px', textDecoration: 'none' }}>Вход</Link>
                    <Link to="/register" style={{ textDecoration: 'none' }}>Регистрация</Link>
                </>
            )}
        </nav>
    );
}

export default Navbar;