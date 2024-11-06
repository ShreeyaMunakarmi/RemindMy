const express = require('express');
const { register, login, getUserData, createReview, createTask, getTasks, updateTaskStatus, updatePassword, getPointsAndCompletedTasks, saveNotification, getNotifications,storePayment, getTotalUsers,getTotalTasks,getTotalDoneTasks, getAllUsers,  getReviews,   deleteUser, getTotalRevenue, getTaskCompletionPercentage  
    } = require('../controllers/authController');
const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', getUserData);
router.post('/reviews', createReview); 
router.post('/tasks', createTask); // New route to create tasks
router.get('/tasks', getTasks); // New route to fetch tasks by status
router.patch('/tasks/status', updateTaskStatus); // New route to update task status
router.patch('/password', updatePassword); // New route to update password
router.get('/points', getPointsAndCompletedTasks); // New route to get points and completed tasks
router.post('/notifications', saveNotification); // New route to save notifications
router.get('/notifications', getNotifications); // New route to fetch notifications
router.post('/payments', storePayment); 
router.get('/users/total', getTotalUsers); // New route to get total users
router.get('/tasks/total', getTotalTasks); // New route to get total tasks
router.get('/tasks/done', getTotalDoneTasks); // New route to get total done tasks
router.get('/users', getAllUsers);
router.get('/reviews', getReviews); 
router.delete('/users/:id', deleteUser);
router.get('/revenue/total', getTotalRevenue); 
router.get('/tasks/completion-percentage', getTaskCompletionPercentage); 

module.exports = router;
