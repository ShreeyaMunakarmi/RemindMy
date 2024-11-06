const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user'); // Import User model

const Review = sequelize.define('Review', {
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
  content: {
    type: DataTypes.TEXT,
    allowNull: false, 
  },
});

Review.belongsTo(User, { foreignKey: 'userId' });
User.hasMany(Review, { foreignKey: 'userId' });

module.exports = Review;