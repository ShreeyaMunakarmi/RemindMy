const { DataTypes } = require('sequelize');
  const sequelize = require('../config/database');
  const User = require('./user');
  
  const Payment = sequelize.define('Payment', {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true
    },
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      references: {
        model: User,
        key: 'id'
      }
    },
    date: {
      type: DataTypes.DATE,
      allowNull: false
    },
    amount: {
      type: DataTypes.INTEGER,
      defaultValue: 1000,
      allowNull: false
    },
    createdAt: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW
    },
    updatedAt: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW
    }
  });
  
  User.hasMany(Payment, { foreignKey: 'userId' });
  Payment.belongsTo(User, { foreignKey: 'userId' });
  
  module.exports = Payment;