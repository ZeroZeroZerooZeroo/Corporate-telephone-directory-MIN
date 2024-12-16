import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function EmployeesReport() {
    const [employees, setEmployees] = useState([]);
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchEmployeesReport = async () => {
            try {
                const response = await apiService.getEmployeesReport();
                setEmployees(response.data);
            } catch (err) {
                console.error(err);
                setError('Ошибка получения отчета по сотрудникам');
            }
        };
        fetchEmployeesReport();
    }, []);

    return (
        <div>
            <h2>Отчет по Сотрудникам</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            {employees.length > 0 ? (
                <table border="1">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Имя</th>
                            <th>Email</th>
                            <th>Телефон</th>
                            <th>Дата трудоустройства</th>
                            <th>Администратор</th>
                            <th>Должность</th>
                            <th>Отдел</th>
                        </tr>
                    </thead>
                    <tbody>
                        {employees.map(emp => (
                            <tr key={emp.id_employee}>
                                <td>{emp.id_employee}</td>
                                <td>{emp.full_name}</td>
                                <td>{emp.email}</td>
                                <td>{emp.phone_number}</td>
                                <td>{new Date(emp.employment_date).toLocaleDateString()}</td>
                                <td>{emp.is_admin ? 'Да' : 'Нет'}</td>
                                <td>{emp.position_name || 'Не назначено'}</td>
                                <td>{emp.department_name || 'Не назначено'}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            ) : (
                <p>Нет данных для отображения.</p>
            )}
        </div>
    );
}

export default EmployeesReport;