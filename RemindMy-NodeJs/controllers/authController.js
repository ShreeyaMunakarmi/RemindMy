const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const Review = require('../models/review');
const TaskDetail = require('../models/taskDetail');
const Notification = require('../models/notification');
const Payment = require('../models/payment');

const JWT_SECRET = '3sIueX5FbB9B1G4vX9+OwI7zFt/P9FPW3sLd0R9MxHQ=';

exports.register = async (req, res) => {
  const { name, phone, email, password } = req.body;

  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      name,
      phone,
      email,
      password: hashedPassword,
    });

    res.status(201).json({ message: 'User registered successfully!' });
  } catch (error) {
    console.error('Registration error:', error); // Log the error to see more details
    res.status(400).json({ error: 'User registration failed!' });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ where: { email } });

    if (!user) {
      return res.status(404).json({ error: 'User not found!' });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(400).json({ error: 'Invalid credentials!' });
    }

    const token = jwt.sign({ id: user.id }, JWT_SECRET, {
      expiresIn: '1h',
    });

    res.status(200).json({ token, userId: user.id });
  } catch (error) {
    res.status(400).json({ error: 'Login failed!' });
  }
};

exports.getUserData = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findOne({ where: { id: decoded.id } });

    if (!user) {
      return res.status(404).json({ error: 'User not found!' });
    }

    res.status(200).json({
      name: user.name,
      email: user.email,
      points: user.points,
      status: user.status,
    });
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized!' });
  }
};

exports.createReview = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');
  const { content } = req.body;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findOne({ where: { id: decoded.id } });

    if (!user) {
      return res.status(404).json({ error: 'User not found!' });
    }

    const review = await Review.create({
      userId: user.id,
      content,
    });

    res.status(201).json({ message: 'Review created successfully!', review });
  } catch (error) {
    console.error('Review error:', error); // Log the error to see more details
    res.status(400).json({ error: 'Failed to create review!' });
  }
};

exports.createTask = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');
  const { plusCode, title, description } = req.body;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findOne({ where: { id: decoded.id } });

    if (!user) {
      return res.status(404).json({ error: 'User not found!' });
    }

    const task = await TaskDetail.create({
      userId: user.id,
      plusCode,
      title,
      description,
      status: 0, // default status as in progress
    });

    res.status(201).json({ message: 'Task created successfully!', task });
  } catch (error) {
    res.status(400).json({ error: 'Failed to create task!' });
  }
};

exports.getTasks = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');
  const { status } = req.query;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const tasks = await TaskDetail.findAll({
      where: { userId: decoded.id, status },
    });

    res.status(200).json(tasks);
  } catch (error) {
    res.status(400).json({ error: 'Failed to fetch tasks!' });
  }
};

exports.updateTaskStatus = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');
  const { taskId, status } = req.body;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const task = await TaskDetail.findOne({
      where: { id: taskId, userId: decoded.id },
    });

    if (!task) {
      return res.status(404).json({ error: 'Task not found!' });
    }

    if (task.status !== 1 && status === 1) {
      // Increment user's points by 5
      const user = await User.findOne({ where: { id: decoded.id } });
      user.points += 5;
      await user.save();
    }

    task.status = status;
    await task.save();

    res.status(200).json({ message: 'Task status updated successfully!' });
  } catch (error) {
    res.status(400).json({ error: 'Failed to update task status!' });
  }
};

exports.updatePassword = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');
  const { currentPassword, newPassword } = req.body;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findOne({ where: { id: decoded.id } });

    if (!user) {
      return res.status(404).json({ error: 'User not found!' });
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ error: 'Current password is incorrect!' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 8);
    user.password = hashedPassword;
    await user.save();

    res.status(200).json({ message: 'Password updated successfully!' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update password!' });
  }
};


exports.getPointsAndCompletedTasks = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findOne({ where: { id: decoded.id } });

    if (!user) {
      return res.status(404).json({ error: 'User not found!' });
    }

    const completedTasks = await TaskDetail.count({
      where: { userId: user.id, status: 1 },
    });

    res.status(200).json({
      points: user.points,
      completedTasks: completedTasks,
    });
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized!' });
  }
};
exports.saveNotification = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');
  const { taskId, title, description } = req.body;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findOne({ where: { id: decoded.id } });

    if (!user) {
      return res.status(404).json({ error: 'User not found!' });
    }

    const notification = await Notification.create({
      userId: user.id,
      taskId: taskId,
      title: title,
      description: description,
    });

    res.status(201).json({ message: 'Notification saved successfully!', notification });
  } catch (error) {
    res.status(400).json({ error: 'Failed to save notification!' });
  }
};

exports.getNotifications = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const notifications = await Notification.findAll({ where: { userId: decoded.id } });

    res.status(200).json(notifications);
  } catch (error) {
    res.status(400).json({ error: 'Failed to fetch notifications!' });
  }
};
exports.storePayment = async (req, res) => {
  const token = req.header('Authorization').replace('Bearer ', '');
  const { date } = req.body;

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await User.findOne({ where: { id: decoded.id } });

    if (!user) {
      return res.status(404).json({ error: 'User not found!' });
    }

    const payment = await Payment.create({
      userId: user.id,
      date,
      amount: 1000,
    });

    
    user.status = 1;
    await user.save();

    res.status(201).json({ message: 'Payment stored successfully!', payment });
  } catch (error) {
    res.status(400).json({ error: 'Failed to store payment!' });
  }
};
exports.getTotalUsers = async (req, res) => {
  try {
    const totalUsers = await User.count();
    res.status(200).json({ totalUsers });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch total users!' });
  }
};


exports.getTotalTasks = async (req, res) => {
  try {
    const totalTasks = await TaskDetail.count();
    res.status(200).json({ totalTasks });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch total tasks!' });
  }
};


exports.getTotalDoneTasks = async (req, res) => {
  try {
    const totalDoneTasks = await TaskDetail.count({ where: { status: 1 } });
    res.status(200).json({ totalDoneTasks });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch total done tasks!' });
  }
};
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.findAll({ attributes: ['name', 'email', 'phone'] });
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ error: 'Failed to get users' });
  }
};
exports.getReviews = async (req, res) => {
  try {
    const reviews = await Review.findAll({
      attributes: ['content', 'createdAt'],
      include: [
        {
          model: User,
          attributes: ['name']
        }
      ],
      order: [['createdAt', 'DESC']]
    });
    res.status(200).json(reviews);
  } catch (error) {
    res.status(500).json({ error: 'Failed to get reviews' });
  }
};

exports.deleteUser = async (req, res) => {
  const { id } = req.params;

  try {
    console.log(`Attempting to delete user with id: ${id}`);

    const user = await User.findOne({ where: { id } });

    if (!user) {
      console.log('User not found');
      return res.status(404).json({ error: 'User not found!' });
    }

    await user.destroy();
    console.log('User deleted successfully');
    res.status(200).json({ message: 'User deleted successfully!' });
  } catch (error) {
    console.error('Deletion error:', error); 
    res.status(500).json({ error: 'Failed to delete user!' });
  }
};
exports.getTotalRevenue = async (req, res) => {
  try {
    const totalRevenue = await Payment.sum('amount');
    res.status(200).json({ totalRevenue });
  } catch (error) {
    console.error('Error fetching total revenue:', error);
    res.status(500).json({ error: 'Failed to fetch total revenue!' });
  }
};
exports.getTaskCompletionPercentage = async (req, res) => {
  try {
    const totalTasks = await TaskDetail.count();
    const completedTasks = await TaskDetail.count({ where: { status: 1 } });

    const completionPercentage = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

    res.status(200).json({ completionPercentage });
  } catch (error) {
    console.error('Error fetching task completion percentage:', error);
    res.status(500).json({ error: 'Failed to fetch task completion percentage!' });
  }
};