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
        <nav>
            <Link to="/">Главная</Link>
            {user && userData.token ? (
                <>
                    <Link to="/profile">Профиль</Link>
                    <Link to="/documents">Документы</Link>
                    <Link to="/business-cards">Визитки</Link>
                    <Link to="/chats">Чаты</Link>
                    <Link to="/events">События</Link>
                    <Link to="/announcements">Объявления</Link>
                    {user.is_admin && <Link to="/admin">Админ</Link>}
                    <button onClick={handleLogout}>Выход</button>
                </>
            ) : (
                <>
                    <Link to="/login">Вход</Link>
                    <Link to="/register">Регистрация</Link>
                </>
            )}
        </nav>
    );
}

export default Navbar;