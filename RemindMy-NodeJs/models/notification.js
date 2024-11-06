const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user');
const TaskDetail = require('./taskDetail');

const Notification = sequelize.define('Notification', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id',
    },
  },
  taskId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: TaskDetail,
      key: 'id',
    },
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  createdAt: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
});

Notification.belongsTo(User, { foreignKey: 'userId' });
Notification.belongsTo(TaskDetail, { foreignKey: 'taskId' });
User.hasMany(Notification, { foreignKey: 'userId' });
TaskDetail.hasMany(Notification, { foreignKey: 'taskId' });

module.exports = Notification;