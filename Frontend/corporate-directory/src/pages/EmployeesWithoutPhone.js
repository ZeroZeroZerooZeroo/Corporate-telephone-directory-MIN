import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function EmployeesWithoutPhone() {
    const [employees, setEmployees] = useState([]);
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchEmployeesWithoutPhone = async () => {
            try {
                const response = await apiService.getEmployeesWithoutPhone();
                setEmployees(response.data);
            } catch (err) {
                console.error(err);
                setError('Ошибка получения отчета по сотрудникам без телефона');
            }
        };
        fetchEmployeesWithoutPhone();
    }, []);

    return (
        <div>
            <h2>Отчет по Сотрудникам Без Телефона</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {employees.length > 0 ? (
                <ul>
                    {employees.map(emp => (
                        <li key={emp.employee_name}>{emp.employee_name}</li>
                    ))}
                </ul>
            ) : (
                <p>Все сотрудники имеют телефонные номера.</p>
            )}
        </div>
    );
}

export default EmployeesWithoutPhone;