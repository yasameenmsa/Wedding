#!/bin/bash

# تحديث وتثبيت الحزم الأساسية (لن يكون هذا الجزء ضرورياً على Windows)
echo "Installing necessary packages (if required)..."

# تثبيت Node.js و npm (يمكن تخطي هذا الجزء إذا كان Node.js مثبت مسبقاً)
echo "Ensure Node.js and npm are installed..."

# تثبيت MongoDB (يمكن تخطي هذا الجزء إذا كان MongoDB مثبت مسبقاً)
echo "Ensure MongoDB is installed and running..."

# إنشاء مجلد المشروع
echo "Creating project directory..."
mkdir -p wedding-message
cd wedding-message

# إعداد Backend (Express.js)
echo "Setting up backend with Express.js..."
mkdir -p backend
cd backend
npm init -y
npm install express mongoose bcryptjs jsonwebtoken cors

# إنشاء الملفات الأساسية للـ Backend
cat <<EOL > server.js
const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect('mongodb://localhost:27017/weddingMessages', { useNewUrlParser: true, useUnifiedTopology: true });

// Mongoose models
const UserSchema = new mongoose.Schema({
    username: String,
    password: String
});

const MessageSchema = new mongoose.Schema({
    name: String,
    email: String,
    message: String
});

const User = mongoose.model('User', UserSchema);
const Message = mongoose.model('Message', MessageSchema);

// Registration endpoint
app.post('/register', async (req, res) => {
    const { username, password } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ username, password: hashedPassword });
    await user.save();
    res.json({ message: 'User registered successfully' });
});

// Login endpoint
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    const user = await User.findOne({ username });
    if (!user || !await bcrypt.compare(password, user.password)) {
        return res.status(400).json({ message: 'Invalid credentials' });
    }
    const token = jwt.sign({ userId: user._id }, 'secretKey', { expiresIn: '1h' });
    res.json({ token });
});

// Create message endpoint
app.post('/messages', async (req, res) => {
    const { name, email, message } = req.body;
    const newMessage = new Message({ name, email, message });
    await newMessage.save();
    res.json({ message: 'Message saved successfully' });
});

// Get messages endpoint (secured)
app.get('/messages', async (req, res) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Token required' });

    jwt.verify(token, 'secretKey', async (err, user) => {
        if (err) return res.status(403).json({ message: 'Invalid token' });
        const messages = await Message.find();
        res.json(messages);
    });
});

// Start the server
app.listen(5000, () => console.log('Server running on port 5000'));
EOL

# العودة إلى المجلد الرئيسي وإعداد Frontend (React)
cd ..
npx create-react-app frontend
cd frontend

# تثبيت Axios للتواصل مع الـ API
npm install axios

# إعداد مكونات React
cat <<EOL > src/App.js
import React, { useState } from 'react';
import axios from 'axios';

function App() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [token, setToken] = useState('');
  const [messages, setMessages] = useState([]);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');

  const register = async () => {
    await axios.post('http://localhost:5000/register', { username, password });
  };

  const login = async () => {
    const response = await axios.post('http://localhost:5000/login', { username, password });
    setToken(response.data.token);
  };

  const fetchMessages = async () => {
    const response = await axios.get('http://localhost:5000/messages', {
      headers: { 'Authorization': \`Bearer \${token}\` }
    });
    setMessages(response.data);
  };

  const sendMessage = async () => {
    await axios.post('http://localhost:5000/messages', { name, email, message });
  };

  return (
    <div>
      <h1>Wedding Messages</h1>
      
      <h2>Register</h2>
      <input type="text" placeholder="Username" onChange={(e) => setUsername(e.target.value)} />
      <input type="password" placeholder="Password" onChange={(e) => setPassword(e.target.value)} />
      <button onClick={register}>Register</button>

      <h2>Login</h2>
      <input type="text" placeholder="Username" onChange={(e) => setUsername(e.target.value)} />
      <input type="password" placeholder="Password" onChange={(e) => setPassword(e.target.value)} />
      <button onClick={login}>Login</button>

      <h2>Messages</h2>
      <button onClick={fetchMessages}>Fetch Messages</button>
      <ul>
        {messages.map((msg, index) => (
          <li key={index}>{msg.name}: {msg.message}</li>
        ))}
      </ul>

      <h2>Send Message</h2>
      <input type="text" placeholder="Name" onChange={(e) => setName(e.target.value)} />
      <input type="email" placeholder="Email" onChange={(e) => setEmail(e.target.value)} />
      <textarea placeholder="Message" onChange={(e) => setMessage(e.target.value)} />
      <button onClick={sendMessage}>Send Message</button>
    </div>
  );
}

export default App;
EOL

# إنهاء العملية
echo "Setup is complete. To start the project:"
echo "1. Open a terminal in the 'backend' directory and run 'node server.js'."
echo "2. Open another terminal in the 'frontend' directory and run 'npm start'."
