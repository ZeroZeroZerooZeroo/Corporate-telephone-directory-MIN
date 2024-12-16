import React, { useState } from 'react';
import EmployeesManagement from './admin/EmployeesManagement';
import AnnouncementsManagement from './admin/AnnouncementsManagement';
import EventsManagement from './admin/EventsManagement';
import ChatsManagement from './admin/ChatsManagement';
import Reports from './admin/Reports';

function Admin() {
    const [activeTab, setActiveTab] = useState('employees');

    const renderTabContent = () => {
        switch(activeTab) {
            case 'employees':
                return <EmployeesManagement />;
            case 'announcements':
                return <AnnouncementsManagement />;
            case 'events':
                return <EventsManagement />;
            case 'chats':
                return <ChatsManagement />;
            case 'reports':
                return <Reports />;
            default:
                return <EmployeesManagement />;
        }
    };

    return (
        <div style={styles.container}>
            <h2>Админ Панель</h2>
            <div style={styles.tabContainer}>
                <button 
                    onClick={() => setActiveTab('employees')} 
                    style={activeTab === 'employees' ? styles.activeTab : styles.tab}
                >
                    Сотрудники
                </button>
                <button 
                    onClick={() => setActiveTab('announcements')} 
                    style={activeTab === 'announcements' ? styles.activeTab : styles.tab}
                >
                    Объявления
                </button>
                <button 
                    onClick={() => setActiveTab('events')} 
                    style={activeTab === 'events' ? styles.activeTab : styles.tab}
                >
                    Мероприятия
                </button>
                <button 
                    onClick={() => setActiveTab('chats')} 
                    style={activeTab === 'chats' ? styles.activeTab : styles.tab}
                >
                    Чаты
                </button>
                <button 
                    onClick={() => setActiveTab('reports')} 
                    style={activeTab === 'reports' ? styles.activeTab : styles.tab}
                >
                    Отчеты
                </button>
            </div>
            <div style={styles.content}>
                {renderTabContent()}
            </div>
        </div>
    );
}

const styles = {
    container: {
        padding: '20px',
    },
    tabContainer: {
        display: 'flex',
        marginBottom: '20px',
        borderBottom: '1px solid #ccc',
    },
    tab: {
        padding: '10px 20px',
        cursor: 'pointer',
        backgroundColor: '#f0f0f0',
        border: 'none',
        borderBottom: '2px solid transparent',
        outline: 'none',
        transition: 'background-color 0.3s',
    },
    activeTab: {
        padding: '10px 20px',
        cursor: 'pointer',
        backgroundColor: '#fff',
        borderBottom: '2px solid #007bff',
        outline: 'none',
        transition: 'background-color 0.3s',
        fontWeight: 'bold',
    },
    content: {
        padding: '20px',
        border: '1px solid #ccc',
        borderRadius: '5px',
        backgroundColor: '#fff',
    },
};

export default Admin;