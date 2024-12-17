import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function CompanyInfo() {
    const [offices, setOffices] = useState([]);
    const [businessCenters, setBusinessCenters] = useState([]);
    const [departments, setDepartments] = useState([]);
    const [positions, setPositions] = useState([]);
    const [activeTab, setActiveTab] = useState('offices');
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            const [officesRes, businessCentersRes, departmentsRes, positionsRes] = await Promise.all([
                apiService.getOffices(),
                apiService.getBusinessCenters(),
                apiService.getDepartments(),
                apiService.getPositions()
            ]);

            setOffices(officesRes.data);
            setBusinessCenters(businessCentersRes.data);
            setDepartments(departmentsRes.data);
            setPositions(positionsRes.data);
        } catch (err) {
            console.error(err);
            setError('Ошибка загрузки информации о компании');
        }
    };

    const renderTabContent = () => {
        switch(activeTab) {
            case 'offices':
                return (
                    <div>
                        <h3>Офисы</h3>
                        <ul>
                            {offices.map(office => (
                                <li key={office.id_office} style={styles.listItem}>
                                    <p><strong>Номер офиса:</strong> {office.office_number}</p>
                                    <p><strong>Бизнес центр:</strong> {office.business_center_address || 'Не определено'}</p>
                                </li>
                            ))}
                        </ul>
                    </div>
                );
            case 'businessCenters':
                return (
                    <div>
                        <h3>Бизнес Центры</h3>
                        <ul>
                            {businessCenters.map(center => (
                                <li key={center.id_business_center} style={styles.listItem}>
                                    <p><strong>ID:</strong> {center.id_business_center}</p>
                                    <p><strong>Адрес:</strong> {center.address}</p>
                                </li>
                            ))}
                        </ul>
                    </div>
                );
            case 'departments':
                return (
                    <div>
                        <h3>Отделы</h3>
                        <ul>
                            {departments.map(dept => (
                                <li key={dept.id_department} style={styles.listItem}>
                                    <p><strong>Название отдела:</strong> {dept.department_name}</p>
                                    <p><strong>Часы работы:</strong> {dept.open_hours} - {dept.close_hours}</p>
                                    <p><strong>Телефон отдела:</strong> {dept.department_phone_number}</p>
                                    <p><strong>Офис:</strong> {dept.office_number || 'Не назначено'}</p>
                                    <p><strong>Бизнес центр:</strong> {dept.business_center_address || 'Не назначено'}</p>
                                </li>
                            ))}
                        </ul>
                    </div>
                );
            case 'positions':
                return (
                    <div>
                        <h3>Должности</h3>
                        <ul>
                            {positions.map(position => (
                                <li key={position.id_position} style={styles.listItem}>
                                    <p><strong>Название должности:</strong> {position.position_name || 'Не назначено'}</p>
                                    <p><strong>Отдел:</strong> {position.department || 'Не назначено'}</p>
                                    <p><strong>Офис:</strong> {position.office_number || 'Не назначено'}</p>
                                    <p><strong>Бизнес центр:</strong> {position.business_center_address || 'Не назначено'}</p>
                                    <p><strong>Дата назначения:</strong> {new Date(position.appointment_date).toLocaleDateString()}</p>
                                </li>
                            ))}
                        </ul>
                    </div>
                );
            default:
                return null;
        }
    };

    return (
        <div style={styles.container}>
            <h2>Информация о компании</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {message && <p style={{ color: 'green' }}>{message}</p>}
            <div style={styles.tabContainer}>
                <button 
                    onClick={() => setActiveTab('offices')} 
                    style={activeTab === 'offices' ? styles.activeTabButton : styles.tabButton}
                >
                    Офисы
                </button>
                <button 
                    onClick={() => setActiveTab('businessCenters')} 
                    style={activeTab === 'businessCenters' ? styles.activeTabButton : styles.tabButton}
                >
                    Бизнес Центры
                </button>
                <button 
                    onClick={() => setActiveTab('departments')} 
                    style={activeTab === 'departments' ? styles.activeTabButton : styles.tabButton}
                >
                    Отделы
                </button>
                <button 
                    onClick={() => setActiveTab('positions')} 
                    style={activeTab === 'positions' ? styles.activeTabButton : styles.tabButton}
                >
                    Должности
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
    },
    tabButton: {
        flex: 1,
        padding: '10px',
        cursor: 'pointer',
        backgroundColor: '#f0f0f0',
        border: '1px solid #ccc',
        borderBottom: 'none',
    },
    activeTabButton: {
        flex: 1,
        padding: '10px',
        cursor: 'pointer',
        backgroundColor: '#fff',
        border: '1px solid #ccc',
        borderBottom: 'none',
        fontWeight: 'bold',
    },
    content: {
        border: '1px solid #ccc',
        padding: '20px',
        backgroundColor: '#fff',
    },
    listItem: {
        marginBottom: '15px',
        padding: '10px',
        border: '1px solid #eee',
        borderRadius: '5px',
    },
};

export default CompanyInfo;