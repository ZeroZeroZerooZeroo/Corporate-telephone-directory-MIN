import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function EmployeePositionDocumentReport() {
    const [report, setReport] = useState([]);
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchReport = async () => {
            try {
                const response = await apiService.generateEmployeePositionDocumentReport();
                setReport(response.data);
            } catch (err) {
                console.error(err);
                setError('Ошибка загрузки отчета');
            }
        };
        fetchReport();
    }, []);

    return (
        <div>
            <h2>Отчет по сотрудникам, должностям и документам</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            <table border="1" cellPadding="10">
                <thead>
                    <tr>
                        <th>Имя сотрудника</th>
                        <th>Email</th>
                        <th>Название должности</th>
                        <th>Название позиции</th>
                        <th>Название документа</th>
                        <th>Описание документа</th>
                        <th>Дата загрузки документа</th>
                    </tr>
                </thead>
                <tbody>
                    {report.map((item, index) => (
                        <tr key={index}>
                            <td>{item.employee_name}</td>
                            <td>{item.employee_email}</td>
                            <td>{item.job_title_name}</td>
                            <td>{item.position_name}</td>
                            <td>{item.document_title}</td>
                            <td>{item.document_description}</td>
                            <td>{new Date(item.document_load_date).toLocaleDateString()}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
    
}
export default EmployeePositionDocumentReport;