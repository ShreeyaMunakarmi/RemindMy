const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user');

const TaskDetail = sequelize.define('TaskDetail', {
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
  plusCode: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  date: {
    type: DataTypes.DATE,
    allowNull: false,
    defaultValue: DataTypes.NOW,
  },
  status: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0, // 0 represents 'in progress'
  },
});

TaskDetail.belongsTo(User, { foreignKey: 'userId' });
User.hasMany(TaskDetail, { foreignKey: 'userId' });

module.exports = TaskDetail;
