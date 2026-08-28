const express = require("express");

const taskRoutes = require("./routes/taskRoutes");

const app = express();


// Middleware
app.use(express.json());


// Route principale
app.get("/", (req, res) => {
  res.json({
    message: "TODO DevOps API",
    version: "1.0.0",
    status: "running"
  });
});


// Routes TODO
app.use("/api/tasks", taskRoutes);


// Gestion des routes inexistantes
app.use((req, res) => {
  res.status(404).json({
    error: "Route introuvable"
  });
});


module.exports = app;