import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import Navbar from './components/Navbar';
import ProtectedRoute from './components/ProtectedRoute';
import CompanyInfo from './pages/CompanyInfo';
import Login from './pages/Login';
import Register from './pages/Register';
import Profile from './pages/Profile';
import Documents from './pages/Documents';
import BusinessCards from './pages/BusinessCards';
import Chats from './pages/Chats';
import PersonalMessages from './pages/PersonalMessages';
import Events from './pages/Events';
import Announcements from './pages/Announcements';

import Admin from './pages/Admin';
import Notifications from './pages/Notifications';





import './App.css';

function App() {
    return (
        <div className="App">
            <Router>
                <Navbar />
                <Routes>
                    <Route path="/" element={<Profile />} />
                    <Route path="/login" element={<Login />} />
                    <Route path="/register" element={<Register />} />
                    
                    <Route 
                        path="/profile" 
                        element={
                            <ProtectedRoute>
                                <Profile />
                            </ProtectedRoute>
                        } 
                    />
                    <Route 
                        path="/documents" 
                        element={
                            <ProtectedRoute>
                                <Documents />
                            </ProtectedRoute>
                        } 
                    />
                    <Route 
                        path="/business-cards" 
                        element={
                            <ProtectedRoute>
                                <BusinessCards />
                            </ProtectedRoute>
                        } 
                    />
                    <Route 
                        path="/chats" 
                        element={
                            <ProtectedRoute>
                                <Chats />
                            </ProtectedRoute>
                        } 
                    />
                    <Route 
                        path="/personal-messages" 
                        element={
                            <ProtectedRoute>
                                <PersonalMessages />
                            </ProtectedRoute>
                        } 
                    />
                    <Route
                    path="/events" 
                        element={
                            <ProtectedRoute>
                                <Events />
                            </ProtectedRoute>
                        }
                    />
                    <Route
                    path="/positions" 
                        element={
                            <ProtectedRoute>
                                <CompanyInfo />
                            </ProtectedRoute>
                        }
                    />
                    <Route 
                        path="/announcements" 
                        element={
                            <ProtectedRoute>
                                <Announcements />
                            </ProtectedRoute>
                        } 
                    />
                     <Route 
                        path="/notifications" 
                        element={
                            <ProtectedRoute>
                                <Notifications />
                            </ProtectedRoute>
                        } 
                    />
                    {/* Роут для администратора */}
                    <Route 
                        path="/admin" 
                        element={
                            <ProtectedRoute adminOnly={true}>
                                <Admin />
                            </ProtectedRoute>
                        } 
                    />
                </Routes>
            </Router>
        </div>
    );
}

export default App;