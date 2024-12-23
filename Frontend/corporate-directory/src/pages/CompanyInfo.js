import React, { useEffect, useState } from 'react';
import apiService from '../services/apiService';

function CompanyInfo() {
    const [offices, setOffices] = useState([]);
    const [businessCenters, setBusinessCenters] = useState([]);
    const [departments, setDepartments] = useState([]);
    const [positions, setPositions] = useState([]);
    const [filteredPositions, setFilteredPositions] = useState([]);
    const [activeTab, setActiveTab] = useState('offices');
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');

    // Фильтры для должностей
    const [filters, setFilters] = useState({
        employee: '',
        position_name: '',
        department: '',
        office_number: '',
        business_center_address: ''
    });

    useEffect(() => {
        fetchData();
    }, []);

    useEffect(() => {
        if (activeTab === 'positions') {
            applyFilters();
        }
    }, [filters, positions, activeTab]);

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
            setFilteredPositions(positionsRes.data);

            console.log('Positions data:', positionsRes.data); // Для отладки
        } catch (err) {
            console.error(err);
            setError('Ошибка загрузки информации о компании');
        }
    };

    const handleFilterChange = (e) => {
        const { name, value } = e.target;
        setFilters(prevFilters => ({
            ...prevFilters,
            [name]: value
        }));
    };

    const applyFilters = () => {
        let filtered = positions;

        if (filters.employee) {
            filtered = filtered.filter(pos => 
                pos.employee && pos.employee.toLowerCase().includes(filters.employee.toLowerCase())
            );
        }
        if (filters.position_name) {
            filtered = filtered.filter(pos => 
                pos.position_name && pos.position_name.toLowerCase().includes(filters.position_name.toLowerCase())
            );
        }
        if (filters.department) {
            filtered = filtered.filter(pos => 
                pos.department && pos.department.toLowerCase().includes(filters.department.toLowerCase())
            );
        }
        if (filters.office_number) {
            filtered = filtered.filter(pos => 
                pos.office_number && pos.office_number.toLowerCase().includes(filters.office_number.toLowerCase())
            );
        }
        if (filters.business_center_address) {
            filtered = filtered.filter(pos => 
                pos.business_center_address && pos.business_center_address.toLowerCase().includes(filters.business_center_address.toLowerCase())
            );
        }

        setFilteredPositions(filtered);
    };

    const resetFilters = () => {
        setFilters({
            employee: '',
            position_name: '',
            department: '',
            office_number: '',
            business_center_address: ''
        });
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
                                <div style={styles.filterContainer}>
                                    <input
                                        type="text"
                                        name="employee"
                                        placeholder="ФИО сотрудника"
                                        value={filters.employee}
                                        onChange={handleFilterChange}
                                        style={styles.filterInput}
                                    />
                                    <input
                                        type="text"
                                        name="position_name"
                                        placeholder="Название должности"
                                        value={filters.position_name}
                                        onChange={handleFilterChange}
                                        style={styles.filterInput}
                                    />
                                    <input
                                        type="text"
                                        name="department"
                                        placeholder="Отдел"
                                        value={filters.department}
                                        onChange={handleFilterChange}
                                        style={styles.filterInput}
                                    />
                                    <input
                                        type="text"
                                        name="office_number"
                                        placeholder="Номер офиса"
                                        value={filters.office_number}
                                        onChange={handleFilterChange}
                                        style={styles.filterInput}
                                    />
                                    <input
                                        type="text"
                                        name="business_center_address"
                                        placeholder="Адрес бизнес центра"
                                        value={filters.business_center_address}
                                        onChange={handleFilterChange}
                                        style={styles.filterInput}
                                    />
                                    <button onClick={resetFilters} style={styles.resetButton}>Сбросить фильтры</button>
                           </div>
                           <table style={styles.table}>
                               <thead>
                                   <tr>
                                       <th>Сотрудник</th>
                                       <th>Название должности</th>
                                       <th>Дата назначения</th>
                                       <th>Отдел</th>
                                       <th>Номер офиса</th>
                                       <th>Адрес бизнес центра</th>
                                   </tr>
                               </thead>
                               <tbody>
                                   {filteredPositions.map(position => (
                                       <tr key={position.id_position}>
                                           <td>{position.employee || 'Не назначено'}</td>
                                           <td>{position.position_name || 'Не назначено'}</td>
                                           <td>{position.appointment_date ? new Date(position.appointment_date).toLocaleDateString() : 'Не назначено'}</td>
                                           <td>{position.department || 'Не назначено'}</td>
                                           <td>{position.office_number || 'Не назначено'}</td>
                                           <td>{position.business_center_address || 'Не назначено'}</td>
                                       </tr>
                                   ))}
                               </tbody>
                           </table>
                           {filteredPositions.length === 0 && <p>Нет данных, соответствующих фильтрам.</p>}
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
       table: {
           width: '100%',
           borderCollapse: 'collapse',
           marginTop: '20px',
       },
       filterContainer: {
           display: 'flex',
           flexWrap: 'wrap',
           gap: '10px',
           marginBottom: '20px',
       },
       filterInput: {
           padding: '8px',
           border: '1px solid #ccc',
           borderRadius: '4px',
           flex: '1 1 200px',
       },
       resetButton: {
           padding: '8px 12px',
           border: 'none',
           backgroundColor: '#f44336',
           color: '#fff',
           cursor: 'pointer',
           borderRadius: '4px',
       }
   };
   
   export default CompanyInfo;