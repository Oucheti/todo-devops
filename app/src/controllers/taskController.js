const pool = require("../config/database");


// GET /api/tasks
const getTasks = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM tasks ORDER BY id DESC"
    );

    res.status(200).json(result.rows);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Erreur lors de la récupération des tâches"
    });
  }
};


// GET /api/tasks/:id
const getTaskById = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      "SELECT * FROM tasks WHERE id = $1",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: "Tâche introuvable"
      });
    }

    res.status(200).json(result.rows[0]);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Erreur lors de la récupération de la tâche"
    });
  }
};


// POST /api/tasks
const createTask = async (req, res) => {
  try {
    const { title, description } = req.body;

    if (!title || title.trim() === "") {
      return res.status(400).json({
        error: "Le titre est obligatoire"
      });
    }

    const result = await pool.query(
      `
      INSERT INTO tasks (title, description)
      VALUES ($1, $2)
      RETURNING *
      `,
      [title, description || null]
    );

    res.status(201).json(result.rows[0]);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Erreur lors de la création de la tâche"
    });
  }
};


// PUT /api/tasks/:id
const updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, completed } = req.body;

    const result = await pool.query(
      `
      UPDATE tasks
      SET
        title = COALESCE($1, title),
        description = COALESCE($2, description),
        completed = COALESCE($3, completed),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $4
      RETURNING *
      `,
      [title, description, completed, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: "Tâche introuvable"
      });
    }

    res.status(200).json(result.rows[0]);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Erreur lors de la modification de la tâche"
    });
  }
};


// DELETE /api/tasks/:id
const deleteTask = async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      "DELETE FROM tasks WHERE id = $1 RETURNING *",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: "Tâche introuvable"
      });
    }

    res.status(200).json({
      message: "Tâche supprimée avec succès"
    });

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Erreur lors de la suppression de la tâche"
    });
  }
};


module.exports = {
  getTasks,
  getTaskById,
  createTask,
  updateTask,
  deleteTask
};